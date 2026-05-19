Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$env:TARGET_OS = "windows"
$env:LOCAL_OS = "windows"
$TIMESTAMP_RFC3161 = "http://timestamp.digicert.com"

New-Item -Path ".\artifacts" -ItemType Directory

Write-Output "Building for amd64"
$env:TARGET_ARCH = "amd64"
$env:LOCAL_ARCH = "amd64"
$env:CGO_ENABLED = 1
& make cinatunnel
if ($LASTEXITCODE -ne 0) { throw "Failed to build cinatunnel for amd64" }
# Sign build
azuresigntool.exe sign -kvu $env:KEY_VAULT_URL -kvi "$env:KEY_VAULT_CLIENT_ID" -kvs "$env:KEY_VAULT_SECRET" -kvc "$env:KEY_VAULT_CERTIFICATE" -kvt "$env:KEY_VAULT_TENANT_ID" -tr "$TIMESTAMP_RFC3161" -d "CinaTunnel Daemon" .\cinatunnel.exe
copy .\cinatunnel.exe .\artifacts\cinatunnel-windows-amd64.exe

Write-Output "Building for 386"
$env:TARGET_ARCH = "386"
$env:LOCAL_ARCH = "386"
$env:CGO_ENABLED = 0
& make cinatunnel
if ($LASTEXITCODE -ne 0) { throw "Failed to build cinatunnel for 386" }
## Sign build
azuresigntool.exe sign -kvu $env:KEY_VAULT_URL -kvi "$env:KEY_VAULT_CLIENT_ID" -kvs "$env:KEY_VAULT_SECRET" -kvc "$env:KEY_VAULT_CERTIFICATE" -kvt "$env:KEY_VAULT_TENANT_ID" -tr "$TIMESTAMP_RFC3161" -d "CinaTunnel Daemon" .\cinatunnel.exe
copy .\cinatunnel.exe .\artifacts\cinatunnel-windows-386.exe
