[CmdletBinding()]
param([Parameter(Mandatory)][string]$MavenVersion,[ValidateSet('stable','maven3-preview','maven4-preview')][string]$Channel,[string]$SourceUrl)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module "$PSScriptRoot/MavenInstaller.Common.psm1" -Force
if(-not $Channel){$Channel=Get-MavenChannelForVersion $MavenVersion}
& "$PSScriptRoot/Build-Installer.ps1" -MavenVersion $MavenVersion -Channel $Channel -SourceUrl $SourceUrl
& "$PSScriptRoot/Generate-WingetManifest.ps1" -MavenVersion $MavenVersion -Channel $Channel
