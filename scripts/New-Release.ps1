[CmdletBinding()] param([Parameter(Mandatory)][string]$MavenVersion,[string]$SourceUrl)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop';& "$PSScriptRoot/Build-Installer.ps1" -MavenVersion $MavenVersion -SourceUrl $SourceUrl;& "$PSScriptRoot/Generate-WingetManifest.ps1" -MavenVersion $MavenVersion
