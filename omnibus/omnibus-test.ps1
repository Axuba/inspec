# Stop script execution when a non-terminating error occurs
$ErrorActionPreference = "Stop"

$channel = "$Env:CHANNEL"
If ([string]::IsNullOrEmpty($channel)) { $channel = "unstable" }

$product = "$Env:PRODUCT"
If ([string]::IsNullOrEmpty($product)) { $product = "inspec" }

$version = "$Env:VERSION"
If ([string]::IsNullOrEmpty($version)) { $version = "latest" }

Write-Output "--- Installing $channel $product $version"
$package_file = $(C:\opscode\omnibus-toolchain\bin\install-omnibus-product.ps1 -Product "$product" -Channel "$channel" -Version "$version" | Select-Object -Last 1)

Write-Output "--- Verifying omnibus package is signed"
C:\opscode\omnibus-toolchain\bin\check-omnibus-package-signed.ps1 "$package_file"

Write-Output "--- Running verification for $channel $product $version"

# reload Env:PATH to ensure it gets any changes that the install made (e.g. C:\opscode\inspec\bin\ )
$Env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

Write-Host "--- Downloading Ruby + DevKit"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
(New-Object System.Net.WebClient).DownloadFile('https://public-cd-buildkite-cache.s3-us-west-2.amazonaws.com/rubyinstaller-devkit-2.6.5-1-x64.exe', 'c:\\rubyinstaller-devkit-2.6.5-1-x64.exe')

Write-Host "--- Installing Ruby + DevKit"
Start-Process c:\rubyinstaller-devkit-2.6.5-1-x64.exe -ArgumentList '/verysilent /dir=C:\\ruby26' -Wait

Write-Host "--- Cleaning up installation"
Remove-Item c:\rubyinstaller-devkit-2.6.5-1-x64.exe -Force

$Env:Path += ";C:\ruby26\bin"
Write-Host "+++ Testing $Plan"

cd test/artifact
rake
