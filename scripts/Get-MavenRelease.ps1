[CmdletBinding(DefaultParameterSetName='Version')]
param(
    [Parameter(Mandatory,ParameterSetName='Version')][string]$MavenVersion,
    [Parameter(ParameterSetName='Version')][string]$SourceUrl,
    [Parameter(Mandatory,ParameterSetName='Discover')][switch]$Discover,
    [Parameter(ParameterSetName='Discover')][ValidateSet('stable','maven3-preview','maven4-preview')][string]$Channel = 'stable'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module "$PSScriptRoot/MavenInstaller.Common.psm1" -Force

if($Discover) {
    $response=Invoke-WebRequest -Uri 'https://maven.apache.org/download.cgi' -UseBasicParsing
    ConvertFrom-MavenDownloadPage -Html $response.Content -Channel $Channel | ConvertTo-Json -Depth 4
} else {
    Get-MavenReleaseInfo -Version $MavenVersion -SourceUrl $SourceUrl | ConvertTo-Json -Depth 4
}
