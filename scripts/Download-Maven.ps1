[CmdletBinding()] param([Parameter(Mandatory)][string]$MavenVersion,[string]$SourceUrl,[string]$OutputDirectory=(Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts/downloads'))
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'; Import-Module "$PSScriptRoot/MavenInstaller.Common.psm1" -Force
$info=Get-MavenReleaseInfo $MavenVersion $SourceUrl; New-Item -ItemType Directory -Force -Path $OutputDirectory|Out-Null
$zip=Join-Path $OutputDirectory $info.ArchiveName; $sha="$zip.sha512"; Invoke-WebRequest -Uri $info.SourceUrl -OutFile $zip -UseBasicParsing; Invoke-WebRequest -Uri $info.ChecksumUrl -OutFile $sha -UseBasicParsing
[pscustomobject]@{ArchivePath=$zip;ChecksumPath=$sha;SourceUrl=$info.SourceUrl;Version=$MavenVersion}|ConvertTo-Json
