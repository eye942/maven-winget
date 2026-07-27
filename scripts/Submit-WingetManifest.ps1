[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$MavenVersion,
    [ValidateSet('stable', 'maven3-preview', 'maven4-preview')][string]$Channel,
    [string]$WingetCreatePath,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot/MavenInstaller.Common.psm1" -Force

if (-not $Channel) {
    $Channel = Get-MavenChannelForVersion $MavenVersion
}
Assert-ChannelVersion -Version $MavenVersion -Channel $Channel

$config = Get-RepositoryConfig
$packageIdentifier = Get-PackageIdentifier $Channel
$tag = Get-ReleaseTag $MavenVersion $Channel
$assetName = "maven-community-$Channel-$MavenVersion-x64.msi"
$releaseAssetUrl = "$($config.RepositoryUrl)/releases/download/$tag/$assetName"
$installerUrls = @(
    "$releaseAssetUrl|x64|user",
    "$releaseAssetUrl|x64|machine"
)

$arguments = @(
    'update', $packageIdentifier,
    '--urls'
) + $installerUrls + @(
    '--version', $MavenVersion,
    '--submit',
    '--no-open'
)

$result = [pscustomobject]@{
    PackageIdentifier = $packageIdentifier
    ReleaseAssetUrl = $releaseAssetUrl
    InstallerUrls = $installerUrls
    Arguments = $arguments
}

if ($DryRun) {
    $result
    return
}

if ([string]::IsNullOrWhiteSpace($env:WINGET_CREATE_GITHUB_TOKEN)) {
    throw 'WINGET_CREATE_GITHUB_TOKEN is required for submission. Configure it as a secret in the protected winget-submission GitHub Environment.'
}
if ([string]::IsNullOrWhiteSpace($WingetCreatePath) -or -not (Test-Path -LiteralPath $WingetCreatePath -PathType Leaf)) {
    throw 'WingetCreatePath must point to the verified wingetcreate.exe downloaded by the release workflow.'
}

# Check before update so an unbootstrapped identity has a useful, non-interactive failure.
& $WingetCreatePath show $packageIdentifier
if ($LASTEXITCODE -ne 0) {
    throw "Upstream package '$packageIdentifier' was not found. Bootstrap it once with 'wingetcreate new' using manifests/generated/$packageIdentifier/$MavenVersion, submit and merge that PR, then rerun a later published release."
}

& $WingetCreatePath @arguments
if ($LASTEXITCODE -ne 0) {
    throw "WingetCreate failed while updating '$packageIdentifier' version '$MavenVersion'. Check the action log for duplicate-version, installer-download, or winget-pkgs validation errors."
}

$result
