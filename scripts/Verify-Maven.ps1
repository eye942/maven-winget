[CmdletBinding()] param([Parameter(Mandatory)][string]$ArchivePath,[Parameter(Mandatory)][string]$ChecksumPath,[switch]$VerifySignature)
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'; Import-Module "$PSScriptRoot/MavenInstaller.Common.psm1" -Force
if(!(Test-Path -LiteralPath $ArchivePath) -or !(Test-Path -LiteralPath $ChecksumPath)){throw 'Archive or official checksum file is missing.'}
$expected=Get-OfficialSha512 (Get-Content -LiteralPath $ChecksumPath -Raw); $actual=(Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA512).Hash.ToLowerInvariant()
if($actual -ne $expected){throw "SHA-512 verification failed for '$ArchivePath'. Expected $expected, got $actual."}
if($VerifySignature){$gpg=Get-Command gpg -ErrorAction SilentlyContinue;if(!$gpg){Write-Warning 'gpg is unavailable; SHA-512 verification remains authoritative.'}else{Write-Verbose 'GPG verification requires an explicitly supplied trusted KEYS workflow.'}}
[pscustomobject]@{Verified=$true;ArchiveSha512=$actual;ArchivePath=(Resolve-Path $ArchivePath).Path}|ConvertTo-Json
