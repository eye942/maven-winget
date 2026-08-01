# WinGet submission

Publishing a reviewed draft release automatically starts the WinGet submission workflow. The existing `release` GitHub Environment is the approval boundary for this job. It must contain a `WINGET_CREATE_GITHUB_TOKEN` secret for an account that can fork and open PRs in `microsoft/winget-pkgs`; pull requests, discovery, and draft-release workflows never receive the token.

## Release environment configuration

Configure the repository's `release` environment with these protection rules:

- Require a trusted reviewer before deployment. Enable **Prevent self-review** when a separate maintainer is available, and disable administrator bypass where appropriate.
- Select **Selected branches and tags** as the deployment policy.
- Add these **tag** rules: `v*`, `maven3-preview-v*`, and `maven4-preview-v*`.
- Add this **branch** rule: `main`. It allows recovery-only manual dispatches for an already published release tag.
- Store the WinGet PAT only as the `WINGET_CREATE_GITHUB_TOKEN` environment secret; do not add it as a repository secret.

The tag rules cover automatic runs after stable and preview releases are published. The `main` branch rule covers a maintainer's explicit recovery dispatch; that job still validates the supplied tag and waits for environment approval.

The draft-release job generates the canonical local manifests and runs `Submit-WingetManifest.ps1 -DryRun`. When that draft is published, the protected job derives the channel and version from the release tag, verifies that the matching MSI asset is non-empty, downloads the pinned WingetCreate standalone executable, verifies its SHA-256, and runs `wingetcreate update --submit`. It submits two scope-qualified references to the same release MSI: `x64|user` and `x64|machine`.

## First release for a new channel

Each new package identity requires a one-time, manual WinGet submission. For example, a future Maven 5 preview channel would need its own package identifier and an initial `microsoft/winget-pkgs` pull request before later releases can use the automatic update workflow. Do not try to automate this first submission with `wingetcreate new`: it requires interactive package-metadata input.

1. Add and merge the new channel's repository configuration: package identifier, product name, automation branch prefix, and release-tag prefix. Extend the channel/version validation, workflow inputs, release-tag parsing, and the `release` environment's allowed **tag** rules for that channel.
2. Merge that support before creating the first release. The new channel must be selectable by the draft-release workflow and must produce a unique release tag and package identifier.
3. Run **prepare Maven draft release** manually for the new channel. Review the MSI, checksums, SBOM, and generated YAML manifests on the draft release.
4. Publish the reviewed draft release. This creates the immutable Git tag and makes the MSI URL in the generated manifests publicly reachable.
5. The automatic WinGet update workflow will start and wait at the `release` environment. Reject that first run: the package identity does not exist upstream yet, so `wingetcreate update` is intentionally unable to submit it.
6. Fork `microsoft/winget-pkgs`, clone the fork locally, and download the generated `*.yaml` release assets into `manifests/generated/<PackageIdentifier>/<Version>` in this repository.
7. Copy the generated manifests into the fork's required layout, validate them, then commit and open the initial PR:

   ```powershell
   ./scripts/Copy-WingetManifests.ps1 -MavenVersion <version> -Channel <channel> -WingetPkgsPath <path-to-your-winget-pkgs-fork>
   winget validate --manifest <path-printed-by-the-script>
   ```

8. Review the PR carefully: the package identifier, MSI URL, SHA-256, architecture, and both user/machine scopes must match the published release. Submit it to `microsoft/winget-pkgs` and wait for it to merge.
9. Do not resubmit the initial version through the automation; it would be a duplicate. The next published release for that channel will use `wingetcreate update --submit` automatically after `release` environment approval.

Microsoft documents the same boundary: the first package version is a manual submission, while later updates can be automated. [Create a package manifest](https://learn.microsoft.com/en-us/windows/package-manager/package/manifest)

## Recovery

The automated run opens a normal upstream PR. A duplicate version means that version is already represented upstream: inspect the existing manifest/PR and do not retry blindly. For installer URL, hash, or schema validation failures, fix the release artifact or canonical generator, publish a corrected release only when appropriate, then use the workflow's `release_tag` manual-dispatch input to resubmit the published release. For local inspection, use:

```powershell
pwsh ./scripts/Submit-WingetManifest.ps1 -MavenVersion 3.9.16 -Channel stable -DryRun
```
