Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RepositoryRoot { Split-Path -Parent $PSScriptRoot }
function Get-RepositoryConfig { Import-PowerShellDataFile (Join-Path (Get-RepositoryRoot) 'RepositoryConfig.psd1') }
function Assert-MavenVersion { param([string]$Version) if ($Version -notmatch '^([3-4])\.(\d+)\.(\d+)(?:-(rc|beta|alpha)-(\d+))?$') { throw "Unsupported Maven version '$Version'. Expected 3.x/4.x semantic version, optionally -rc-N, -beta-N, or -alpha-N." } }
function Get-MavenReleaseInfo {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Version, [string]$SourceUrl)
    Assert-MavenVersion $Version
    $archive = "apache-maven-$Version-bin.zip"
    if (-not $SourceUrl) { $SourceUrl = "https://dlcdn.apache.org/maven/maven-$(($Version -split '\.')[0])/$Version/binaries/$archive" }
    [pscustomobject]@{ Version=$Version; ArchiveName=$archive; SourceUrl=$SourceUrl; ChecksumUrl="$SourceUrl.sha512"; SignatureUrl="$SourceUrl.asc"; IsPrerelease=($Version -match '-'); Family="Maven$(([int]($Version -split '\.')[0]))" }
}
function Get-MsiVersion {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Version)
    Assert-MavenVersion $Version
    if ($Version -notmatch '-') { return $Version }
    $m=[regex]::Match($Version,'^(\d+)\.(\d+)\.(\d+)-(rc|beta|alpha)-(\d+)$'); $kind=@{alpha=1;beta=2;rc=3}[$m.Groups[4].Value];
    # MSI only accepts numeric fields. Fourth field is 1000 + prerelease class*100 + sequence.
    return "$($m.Groups[1].Value).$($m.Groups[2].Value).$($m.Groups[3].Value).$(1000 + (100*$kind) + [int]$m.Groups[5].Value)"
}
function Get-UpgradeCode { param([string]$Version) $c=Get-RepositoryConfig; if ($Version.StartsWith('3.')) { $c.Maven3UpgradeCode } else { $c.Maven4UpgradeCode } }
function Get-PathEntry { param([Parameter(Mandatory)][string]$InstallDirectory) (Join-Path $InstallDirectory 'bin').TrimEnd('\') }
function Get-OfficialSha512 {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$ChecksumText)
    $m=[regex]::Match($ChecksumText,'(?im)\b([A-F0-9]{128})\b'); if (-not $m.Success) { throw 'Official checksum response did not contain a SHA-512 value.' }; $m.Groups[1].Value.ToLowerInvariant()
}
function Test-PathEntryPresent { param([string]$PathValue,[string]$Entry) @($PathValue -split ';' | ForEach-Object {$_.TrimEnd('\')}) -contains $Entry.TrimEnd('\') }
Export-ModuleMember -Function *
