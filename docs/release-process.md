# Release process

1. Run `New-Release.ps1` for the target version and review `artifacts/release-metadata.json`.
2. Run Pester and an integration install in a disposable Windows VM/runner.
3. Dispatch `release.yml`; it verifies upstream content before any GitHub Release step.
4. Review uploaded MSI, checksums, SBOM, and manifest bundle, then submit manifests.

The scheduled workflow only opens an update PR; maintainers review and explicitly release it.
