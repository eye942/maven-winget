[CmdletBinding()] param([Parameter(Mandatory)][string]$MavenVersion,[ValidateSet('Machine','User')][string]$Scope='Machine',[string]$SourceUrl)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop';& "$PSScriptRoot/Build-Installer.ps1" -MavenVersion $MavenVersion -Scope $Scope -SourceUrl $SourceUrl;& "$PSScriptRoot/Generate-WingetManifest.ps1" -MavenVersion $MavenVersion -Scope $Scope
