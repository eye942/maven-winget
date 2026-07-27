Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RepositoryRoot { Split-Path -Parent $PSScriptRoot }
function Get-RepositoryConfig { Import-PowerShellDataFile (Join-Path (Get-RepositoryRoot) 'RepositoryConfig.psd1') }
function Assert-MavenVersion { param([string]$Version) if ($Version -notmatch '^([3-4])\.(\d+)\.(\d+)(?:-(rc|beta|alpha)-(\d+))?$') { throw "Unsupported Maven version '$Version'. Expected 3.x/4.x semantic version, optionally -rc-N, -beta-N, or -alpha-N." } }
function Assert-MavenChannel {
    param([Parameter(Mandatory)][string]$Channel)
    if ($Channel -notin @('stable','maven3-preview','maven4-preview')) { throw "Unsupported Maven channel '$Channel'." }
}
function Get-MavenChannelConfiguration {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Channel)
    Assert-MavenChannel $Channel
    (Get-RepositoryConfig).Channels[$Channel]
}
function Get-MavenChannelForVersion {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Version)
    Assert-MavenVersion $Version
    if ($Version -notmatch '-') { return 'stable' }
    if ($Version.StartsWith('3.')) { return 'maven3-preview' }
    return 'maven4-preview'
}
function Assert-ChannelVersion {
    param([Parameter(Mandatory)][string]$Version,[Parameter(Mandatory)][string]$Channel)
    $actual=Get-MavenChannelForVersion $Version
    if ($actual -ne $Channel) { throw "Version '$Version' belongs to '$actual', not '$Channel'." }
}
function Get-MavenReleaseInfo {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Version, [string]$SourceUrl, [string]$Channel)
    Assert-MavenVersion $Version
    if (-not $Channel) { $Channel=Get-MavenChannelForVersion $Version } else { Assert-ChannelVersion $Version $Channel }
    $archive = "apache-maven-$Version-bin.zip"
    if (-not $SourceUrl) { $SourceUrl = "https://dlcdn.apache.org/maven/maven-$(($Version -split '\.')[0])/$Version/binaries/$archive" }
    $uri=[Uri]$SourceUrl
    if ($uri.Scheme -ne 'https' -or $uri.Host -ne 'dlcdn.apache.org' -or -not $uri.AbsolutePath.EndsWith("/$archive")) { throw "Source URL must be the official dlcdn.apache.org archive URL for '$archive'." }
    [pscustomobject]@{ Version=$Version; Channel=$Channel; ArchiveName=$archive; SourceUrl=$SourceUrl; ChecksumUrl="$SourceUrl.sha512"; SignatureUrl="$SourceUrl.asc"; IsPrerelease=($Version -match '-'); Family="Maven$(([int]($Version -split '\.')[0]))"; PublishDate=$null }
}
function Get-MsiVersion {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Version)
    Assert-MavenVersion $Version
    if ($Version -notmatch '-') { return $Version }
    $m=[regex]::Match($Version,'^(\d+)\.(\d+)\.(\d+)-(rc|beta|alpha)-(\d+)$'); $kind=@{alpha=1;beta=2;rc=3}[$m.Groups[4].Value]
    return "$($m.Groups[1].Value).$($m.Groups[2].Value).$($m.Groups[3].Value).$(1000 + (100*$kind) + [int]$m.Groups[5].Value)"
}
function Get-UpgradeCode { (Get-RepositoryConfig).MavenUpgradeCode }
function Get-PackageIdentifier { param([Parameter(Mandatory)][string]$Channel) (Get-MavenChannelConfiguration $Channel).PackageIdentifier }
function Get-ProductName { param([Parameter(Mandatory)][string]$Channel) (Get-MavenChannelConfiguration $Channel).ProductName }
function Get-ReleaseTag { param([Parameter(Mandatory)][string]$Version,[Parameter(Mandatory)][string]$Channel) "$(Get-MavenChannelConfiguration $Channel | Select-Object -ExpandProperty ReleaseTagPrefix)$Version" }
function Get-PathEntry { param([Parameter(Mandatory)][string]$InstallDirectory) (Join-Path $InstallDirectory 'bin').TrimEnd('\\') }
function Get-OfficialSha512 {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$ChecksumText)
    $m=[regex]::Match($ChecksumText,'(?im)\b([A-F0-9]{128})\b'); if (-not $m.Success) { throw 'Official checksum response did not contain a SHA-512 value.' }; $m.Groups[1].Value.ToLowerInvariant()
}
function Test-PathEntryPresent { param([string]$PathValue,[string]$Entry) @($PathValue -split ';' | ForEach-Object {$_.TrimEnd('\\')}) -contains $Entry.TrimEnd('\\') }
function ConvertFrom-MavenDownloadPage {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Html,[Parameter(Mandatory)][string]$Channel)
    Assert-MavenChannel $Channel
    $dateMatch=[regex]::Match($Html,'(?is)id\s*=\s*["'']publishDate["''][^>]*>(.*?)</li>')
    if(-not $dateMatch.Success){ throw 'Apache download page did not contain the required #publishDate element.' }
    $links=[regex]::Matches($Html,'https://dlcdn\.apache\.org/maven/maven-[34]/[^"''<\s]+/binaries/apache-maven-([0-9]+\.[0-9]+\.[0-9]+(?:-(?:rc|beta|alpha)-[0-9]+)?)-bin\.zip')
    $candidates=@($links | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique | ForEach-Object { Get-MavenReleaseInfo -Version $_ })
    $match=@($candidates | Where-Object { $_.Channel -eq $Channel })
    if($match.Count -ne 1){ throw "Expected exactly one current '$Channel' ZIP link on Apache's download page; found $($match.Count)." }
    $publishText=([regex]::Replace($dateMatch.Groups[1].Value,'(?is)<[^>]+>',' ') -replace '\s+',' ').Trim()
    $published=[regex]::Match($publishText,'\b\d{4}-\d{2}-\d{2}\b')
    if(-not $published.Success){ throw 'Apache #publishDate did not contain an ISO publication date.' }
    $publishDate=$published.Value
    $result=$match[0]; $result.PublishDate=$publishDate; return $result
}
function Get-ReleaseState { Get-Content -Raw (Join-Path (Get-RepositoryRoot) 'config/ReleaseState.json') | ConvertFrom-Json -Depth 10 }
Export-ModuleMember -Function *
