[CmdletBinding()] param([Parameter(Mandatory)][string]$MavenVersion,[string]$SourceUrl)
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'; Import-Module "$PSScriptRoot/MavenInstaller.Common.psm1" -Force
Get-MavenReleaseInfo -Version $MavenVersion -SourceUrl $SourceUrl | ConvertTo-Json -Depth 3
