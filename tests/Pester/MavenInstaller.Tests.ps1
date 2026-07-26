Describe 'Maven release helpers' {
 BeforeAll { Import-Module "$PSScriptRoot/../../scripts/MavenInstaller.Common.psm1" -Force }
 It 'parses Maven 3 stable versions' { (Get-MavenReleaseInfo '3.9.16').ArchiveName | Should -Be 'apache-maven-3.9.16-bin.zip' }
 It 'parses Maven 4 prereleases' { (Get-MsiVersion '4.0.0-rc-4') | Should -Be '4.0.0.1304' }
 It 'constructs official URLs' { (Get-MavenReleaseInfo '3.9.16').SourceUrl | Should -Match '^https://dlcdn.apache.org/maven/' }
 It 'rejects bad versions' { { Assert-MavenVersion 'x' } | Should -Throw }
 It 'extracts official checksums' { Get-OfficialSha512 ('a'*128) | Should -Be ('a'*128) }
 It 'formats paths with spaces' { Get-PathEntry 'C:\Program Files\Apache Maven\apache-maven-3.9.16' | Should -Be 'C:\Program Files\Apache Maven\apache-maven-3.9.16\bin' }
 It 'recognizes a duplicate PATH entry' { Test-PathEntryPresent 'C:\a;C:\b\bin' 'C:\b\bin' | Should -BeTrue }
}
