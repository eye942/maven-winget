[CmdletBinding()] param([Parameter(Mandatory)][string]$MavenVersion,[ValidateSet('stable','maven3-preview','maven4-preview')][string]$Channel,[ValidateSet('Machine','User')][string]$Scope='User',[switch]$Integration)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop';$root=Split-Path $PSScriptRoot -Parent;Import-Module "$PSScriptRoot/MavenInstaller.Common.psm1" -Force
if(-not $Channel){$Channel=Get-MavenChannelForVersion $MavenVersion}
$pester=Get-Command Invoke-Pester -ErrorAction SilentlyContinue
if(!$pester){throw 'Pester 5+ is required. Install-Module Pester -Force -MinimumVersion 5.0.0'}
$pesterVersion=(Get-Module Pester).Version;if($pesterVersion.Major -lt 5){throw "Pester 5+ is required; found $pesterVersion."}
$result=Invoke-Pester -Path "$root/tests/Pester" -CI -PassThru
if($result.FailedCount -gt 0){throw "$($result.FailedCount) Pester test(s) failed."}
if($Integration){$msi=Join-Path $root "artifacts/maven-community-$Channel-$MavenVersion-x64.msi";if(!(Test-Path $msi)){throw 'Build the MSI first.'};$log=Join-Path $env:TEMP 'maven-community-msi.log';$scopeArgs=if($Scope -eq 'Machine'){'ALLUSERS=1 MSIINSTALLPERUSER=""'}else{'ALLUSERS=2 MSIINSTALLPERUSER=1'};$args="/i `"$msi`" $scopeArgs /qn /norestart /l*v `"$log`"";$p=Start-Process msiexec.exe -ArgumentList $args -Wait -PassThru;if($p.ExitCode -ne 0){throw "MSI install failed; inspect $log"};Write-Host 'Installed. Run Maven checks in a fresh process after installing a JDK.'}
