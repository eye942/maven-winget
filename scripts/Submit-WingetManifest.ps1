[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ManifestDirectory,
    [Parameter(Mandatory)][string]$PackageIdentifier,
    [Parameter(Mandatory)][string]$Version,
    [string]$WingetCreatePath,
    [switch]$DryRun,
    # Test-only override: when supplied, the package is treated as existing with these versions.
    [string[]]$ExistingVersions
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ManifestDirectory -PathType Container)) {
    throw "ManifestDirectory must be an existing directory: $ManifestDirectory"
}
if (-not $DryRun -and [string]::IsNullOrWhiteSpace($env:WINGET_CREATE_GITHUB_TOKEN)) {
    throw 'WINGET_CREATE_GITHUB_TOKEN is required for submission. Configure it as a secret in the protected release GitHub Environment.'
}

function Get-SubmissionClassification {
    param([string[]]$Versions, [bool]$PackageExists)

    if (-not $PackageExists) { return 'New package' }
    if ($Versions -notcontains $Version) { return 'Add version' }
    return 'Update version'
}

$packageExists = $false
$knownVersions = @()
if ($PSBoundParameters.ContainsKey('ExistingVersions')) {
    $packageExists = $true
    $knownVersions = @($ExistingVersions)
} elseif (-not $DryRun) {
    if ([string]::IsNullOrWhiteSpace($WingetCreatePath) -or -not (Test-Path -LiteralPath $WingetCreatePath -PathType Leaf)) {
        throw 'WingetCreatePath must point to the verified wingetcreate.exe downloaded by the release workflow.'
    }

    & $WingetCreatePath show $PackageIdentifier 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $packageExists = $true
        & $WingetCreatePath show $PackageIdentifier --version $Version 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { $knownVersions = @($Version) }
    }
}

$classification = Get-SubmissionClassification -Versions $knownVersions -PackageExists $packageExists
$prTitle = "$classification`: $PackageIdentifier version $Version"
$arguments = @('submit', '--prtitle', $prTitle, '--no-open')
if ($classification -eq 'Update version') { $arguments += @('--replace', $Version) }
$arguments += $ManifestDirectory

$result = [pscustomobject]@{
    PackageIdentifier = $PackageIdentifier
    Version = $Version
    ManifestDirectory = $ManifestDirectory
    Classification = $classification
    PrTitle = $prTitle
    Arguments = $arguments
}

if ($DryRun) {
    $result
    return
}

& $WingetCreatePath @arguments
if ($LASTEXITCODE -ne 0) {
    throw "WingetCreate failed while submitting '$PackageIdentifier' version '$Version'. Check the action log for manifest validation or winget-pkgs submission errors."
}

$result
