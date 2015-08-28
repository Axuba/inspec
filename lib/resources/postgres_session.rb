# encoding: utf-8
# copyright: 2015, Vulcano Security GmbH
# license: All rights reserved

class Lines
  def initialize raw, desc
    @raw = raw
    @desc = desc
  end

  def output
    @raw
  end

  def lines
    @raw.split("\n")
  end

  def to_s
    @desc
  end
end

class PostgresSession
  def initialize user, pass
    @user = user || 'postgres'
    @pass = pass
  end

  def describe(query, db = [], &block)
    dbs = db.map{|x| "-d #{x}" }.join(' ')
    # TODO: simple escape, must be handled by a library
    # that does this securely
    escaped_query = query.gsub(/\\/, '\\\\').gsub(/"/,'\\"').gsub(/\$/,'\\$')
    # run the query
    cmd = @vulcano.run_command("PGPASSWORD='#{@pass}' psql -U #{@user} #{dbs} -c \"#{escaped_query}\"")
    out = cmd.stdout + "\n" + cmd.stderr
    if out =~ /could not connect to .*/ or
       out.downcase =~ /^error/
      # skip this test if the server can't run the query
      RSpec.describe( cmd ) do
        it "is skipped", skip: out do
        end
      end
    else
      lines = cmd.stdout.
        # remove the whole header (i.e. up to the first ^-----+------+------$)
        sub(/(.*\n)+([-]+[+])*[-]+\n/,'').
        # remove the tail
        sub(/\n[^\n]*\n\n$/,'')
      l = Lines.new(lines.strip, "PostgreSQL query: #{query}")
      RSpec.__send__( 'describe', l, &block )
    end
  end

end
