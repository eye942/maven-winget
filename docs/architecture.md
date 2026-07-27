# Architecture

Maven's `bin\mvn.cmd` discovers `MAVEN_HOME` relative to itself, so a raw ZIP marked `NestedInstallerType: portable`, a WinGet links-directory copy, or a detached native launcher can break Maven's layout. This project builds an MSI with WiX v7 after verifying and extracting the upstream ZIP. WiX's native `Files` element harvests the named payload bind path without modifying the archive tree. PATH targets Maven's actual `bin` directory. `MAVEN_HOME` is not set because Maven's launcher already locates itself and global variables create conflicts.

One dual-purpose MSI is produced. WiX `Scope="perUserOrMachine"` uses Windows Installer's `ALLUSERS=2` / `MSIINSTALLPERUSER` scope model; WinGet emits separate user and machine installer records for the same hashed asset and supplies the appropriate properties. Conditional WiX Environment components add Maven's real `bin` directory to user or system PATH. The WiX Environment table owns its entry so major upgrade/uninstall removes that entry only. No custom action touches `.m2`.

WinGet uses separate identities for release channels: `eye942.Maven` for stable, `eye942.Maven.Maven3Preview` for Maven 3 previews, and `eye942.Maven.Maven4Preview` for Maven 4 previews. The MSI deliberately uses one upgrade family across these channels: Maven launchers all expose `mvn`, so a channel switch removes the previous MSI-owned PATH entry rather than allowing conflicting commands. MSI cannot represent prerelease labels, so `X.Y.Z-rc-N` maps deterministically to `X.Y.Z.1300+N` (`alpha=1100+N`, `beta=1200+N`). WinGet keeps the original upstream version.

The discovery workflow parses Apache's `download.cgi` and requires its `#publishDate` element. Stable, Maven 3 preview, and Maven 4 preview use independent PR branches, release-state entries, draft-release tags, and manifests. Merging an approved candidate rebuilds from the official ZIP and checksum and creates only a draft; a maintainer explicitly runs the publish workflow.

The trust chain is Apache ZIP + official SHA-512 → workflow artifact → community GitHub release MSI → WinGet SHA-256. Java is not bundled or declared as a vendor dependency: choosing a JDK is a user policy decision.

Alternatives considered: a raw portable ZIP and copied launcher violate relative layout; native launchers add code; PowerShell/Chocolatey scripts are less transactional; Inno Setup/NSIS lack MSI enterprise integration; MSIX is awkward for PATH and classic directory layout. WiX/MSI provides rollback, repair, ARP, major upgrades, silent deployment, and native environment support.
