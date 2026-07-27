# Release process

1. The weekly discovery workflow reads Apache's `download.cgi` and its `#publishDate` for the stable, Maven 3 preview, and Maven 4 preview streams. It opens one review PR per channel.
2. Review the PR's upstream ZIP and checksum URLs. CI independently verifies SHA-512, builds the channel MSI, and attaches the release-preview bundle.
3. Merge the candidate PR. `prepare-release.yml` rebuilds from verified inputs and creates a channel-specific GitHub draft release.
4. Review the draft. Dispatch `release.yml` with the exact version and channel to publish it; this rebuilds and verifies before publication.
5. After GitHub Release publication succeeds, the protected `winget-submission` environment runs WingetCreate and opens the update PR in `microsoft/winget-pkgs`.

The streams are `eye942.Maven`, `eye942.Maven.Maven3Preview`, and `eye942.Maven.Maven4Preview`. Preview streams never replace the stable package identity, but their MSI installation deliberately replaces another active Maven channel in the same scope so that `mvn` stays unambiguous.

## Discovery workflow authorization

`update-maven.yml` pins `peter-evans/create-pull-request` to an immutable commit. If discovery jobs fail during setup with an action-resolution error, verify that pin against the action's official release metadata before changing workflow behavior.

The pull-request action receives `secrets.RELEASE_PR_TOKEN` explicitly. The discovery job uses the protected `release` GitHub Environment, whose deployment policy permits only protected branches. This is deliberate: a manual dispatch from a feature or PR branch does not receive the secret and reports `Input 'token' not supplied`. Validate discovery PR creation after the workflow is merged to a protected branch (or through its scheduled run), not from an unprotected branch.

Configure `RELEASE_PR_TOKEN` as a secret of the `release` environment. Its token must be authorized to push the channel branches and open pull requests in this repository.
