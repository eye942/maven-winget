[CmdletBinding()]
param([Parameter(Mandatory)][string]$MavenVersion,[ValidateSet('stable','maven3-preview','maven4-preview')][string]$Channel,[string]$SourceUrl,[string]$OutputDirectory=(Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts/downloads'))
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'; Import-Module "$PSScriptRoot/MavenInstaller.Common.psm1" -Force
if(-not $Channel){$Channel=Get-MavenChannelForVersion $MavenVersion}
$info=Get-MavenReleaseInfo $MavenVersion $SourceUrl $Channel; New-Item -ItemType Directory -Force -Path $OutputDirectory|Out-Null
$zip=Join-Path $OutputDirectory $info.ArchiveName; $sha="$zip.sha512"; Invoke-WebRequest -Uri $info.SourceUrl -OutFile $zip -UseBasicParsing; Invoke-WebRequest -Uri $info.ChecksumUrl -OutFile $sha -UseBasicParsing
[pscustomobject]@{ArchivePath=$zip;ChecksumPath=$sha;SourceUrl=$info.SourceUrl;Version=$MavenVersion;Channel=$Channel}|ConvertTo-Json
