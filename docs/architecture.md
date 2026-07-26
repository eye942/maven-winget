# Architecture

Maven's `bin\mvn.cmd` discovers `MAVEN_HOME` relative to itself, so a raw ZIP marked `NestedInstallerType: portable`, a WinGet links-directory copy, or a detached native launcher can break Maven's layout. This project builds an MSI with WiX v4 after verifying and extracting the upstream ZIP. The payload tree is unchanged; PATH targets its actual `bin` directory. `MAVEN_HOME` is not set because Maven's launcher already locates itself and global variables create conflicts.

Two MSI artifacts are intentionally produced for reliability: machine packages install below `%ProgramFiles%\Apache Maven`, use system PATH, and are run with `ALLUSERS=1`; user packages install below `%LocalAppData%\Programs\Apache Maven`, use user PATH. The WiX Environment table owns its entry so major upgrade/uninstall removes that entry only. No custom action touches `.m2`.

Maven 3 and Maven 4 use separate stable upgrade codes, preventing cross-major replacement. MSI cannot represent prerelease labels, so `X.Y.Z-rc-N` maps deterministically to `X.Y.Z.1300+N` (`alpha=1100+N`, `beta=1200+N`). WinGet keeps the original upstream version. `Community.Maven` identifies the community package, never Apache as publisher.

The trust chain is Apache ZIP + official SHA-512 → workflow artifact → community GitHub release MSI → WinGet SHA-256. Java is not bundled or declared as a vendor dependency: choosing a JDK is a user policy decision.

Alternatives considered: a raw portable ZIP and copied launcher violate relative layout; native launchers add code; PowerShell/Chocolatey scripts are less transactional; Inno Setup/NSIS lack MSI enterprise integration; MSIX is awkward for PATH and classic directory layout. WiX/MSI provides rollback, repair, ARP, major upgrades, silent deployment, and native environment support.
