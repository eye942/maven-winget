[CmdletBinding()]
param([Parameter(Mandatory)][string]$MavenVersion,[Parameter(Mandatory)][string]$WingetPkgsPath,[ValidateSet('stable','maven3-preview','maven4-preview')][string]$Channel)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module "$PSScriptRoot/MavenInstaller.Common.psm1" -Force
if(-not $Channel){$Channel=Get-MavenChannelForVersion $MavenVersion}
$root=Get-RepositoryRoot
$id=Get-PackageIdentifier $Channel
$src=Join-Path $root "manifests/generated/$id/$MavenVersion"
if(!(Test-Path $src)){throw 'Generate manifests first.'}
$segments=$id -split '\.'
$dest=Join-Path $WingetPkgsPath ((@('manifests') + ($segments | ForEach-Object { $_.Substring(0,1).ToLowerInvariant(); $_ })) -join '\\')
$dest=Join-Path $dest $MavenVersion
New-Item -ItemType Directory -Force -Path $dest|Out-Null
Copy-Item "$src/*" $dest -Force
Write-Output $dest
