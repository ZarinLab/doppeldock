# Security policy

## Supported versions

Only the latest release of DoppelDock gets fixes. To update, install it again
the same way you installed it (see the README).

## Verifying a download

Every `DoppelDock.dmg` is built by this repository's
[Release workflow](.github/workflows/release.yml) from the tagged code, and
GitHub records signed build provenance for it. To check a download with the
[GitHub CLI](https://cli.github.com/):

```bash
gh attestation verify DoppelDock.dmg -R ZarinLab/doppeldock
```

Each release also has the DMG's SHA-256 checksum (`DoppelDock.dmg.sha256`) and, from 1.1.1 on, the signed provenance itself (`DoppelDock.dmg.intoto.jsonl`).

## How the project is protected

- Secret scanning with push protection, and Dependabot alerts.
- CodeQL code scanning of the GitHub Actions workflows, and
  [zizmor](https://docs.zizmor.sh/) and actionlint on every change.
- Every action pinned to a full commit hash; Dependabot proposes updates only
  after they have been out for two weeks.
- Workflows run with the least permissions they need.
- `main` can't be force-pushed or deleted, and changes need passing CI.
- A weekly [OpenSSF Scorecard](https://scorecard.dev/viewer/?uri=github.com/ZarinLab/doppeldock) check.

## Reporting a problem

Please **don't** open a public issue for a security problem. Report it
privately through
[Security › Report a vulnerability](https://github.com/ZarinLab/doppeldock/security/advisories/new).

Include what you found, how to reproduce it, and which macOS and app versions
you used. You can expect a first reply within a week. Once a fix is released,
the report is published with credit to you, unless you'd rather stay anonymous.

## What counts

Examples of what we want to hear about:

- DoppelDock deleting, overwriting or exposing data it shouldn't (another app,
  the original app, a profile's data, files outside its own folders).
- Ways a crafted app, profile name or setting could run commands or change
  files.
- Problems in the install line or in how profiles rebuild themselves.

By design, and documented in the README and `docs/details.md`: an own icon copy
is signed on your Mac instead of by the app's maker, and accepts code libraries
not signed by the maker. Reports that only restate this are not
vulnerabilities, but ideas to reduce it are welcome as issues.
