[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$MavenVersion,
    [ValidateSet('stable','maven3-preview','maven4-preview')][string]$Channel,
    [string]$SourceUrl,
    [string]$PublishDate
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module "$PSScriptRoot/MavenInstaller.Common.psm1" -Force

if(-not $Channel){ $Channel=Get-MavenChannelForVersion $MavenVersion }
$info=Get-MavenReleaseInfo -Version $MavenVersion -Channel $Channel -SourceUrl $SourceUrl
$root=Get-RepositoryRoot
$statePath=Join-Path $root 'config/ReleaseState.json'
$state=Get-Content -Raw $statePath | ConvertFrom-Json -Depth 10
$entry=$state.channels.$Channel
if($null -eq $entry){ throw "Release state does not define channel '$Channel'." }
if($null -ne $entry.lastDiscovered -and $entry.lastDiscovered.version -eq $info.Version -and $entry.lastDiscovered.sourceUrl -eq $info.SourceUrl -and $entry.lastDiscovered.publishDate -eq $PublishDate) {
    Write-Output "No new $Channel release was discovered."
    return
}
$entry.lastDiscovered=[ordered]@{
    version=$info.Version; sourceUrl=$info.SourceUrl; checksumUrl=$info.ChecksumUrl
    publishDate=$PublishDate; discoveredAt=(Get-Date).ToUniversalTime().ToString('o')
}
$state | ConvertTo-Json -Depth 10 | Set-Content -NoNewline $statePath
Write-Output "Updated $Channel discovery state for Maven $MavenVersion."
