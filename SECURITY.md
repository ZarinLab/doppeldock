# Security policy

What DoppelDock does and doesn't promise, and why: [security model and assurance case](docs/security.md).

## Supported versions

Only the latest release of DoppelDock gets fixes. To update, install it again
the same way you installed it (see the README).

## Reporting a problem

Please **don't** open a public issue for a security problem. Report it
privately through
[Security › Report a vulnerability](https://github.com/ZarinLab/doppeldock/security/advisories/new).

Include what you found, how to reproduce it, and which macOS and app versions
you used.

## How reports are handled

1. **Acknowledge** the report within 7 days.
2. **Assess** it within 14 days: confirm the problem, its severity and which
   versions are affected, and agree a timeline with the reporter.
3. **Fix** it privately in a GitHub security advisory, with a regression test.
   Critical problems are fixed as fast as possible; others within 60 days of
   becoming public at the latest.
4. **Release** a new version, and list the fix in the
   [changelog](CHANGELOG.md) and the release notes.
5. **Publish** the advisory (with a CVE where appropriate), crediting the
   reporter by name unless they ask to stay anonymous.

If a report turns out not to be a vulnerability, the reporter is told why.

## What counts

Examples of what we want to hear about:

- DoppelDock deleting, overwriting or exposing data it shouldn't (another app,
  the original app, a profile's data, files outside its own folders).
- Ways a crafted app, profile name or setting could run commands or change
  files.
- Problems in the install line, the release files or in how profiles rebuild
  themselves.

By design, and documented in [docs/security.md](docs/security.md): an own icon
copy is signed on your Mac instead of by the app's maker, and accepts code
libraries not signed by the maker. Reports that only restate this are not
vulnerabilities, but ideas to reduce it are welcome as issues.

## Verifying a download

Release files are built by this repository's
[Release workflow](.github/workflows/release.yml) from the tagged code, and
GitHub signs their build provenance with Sigstore (keyless: there is no
private key to obtain or lose; the signature is tied to the workflow's
identity). To check a release file from 1.1.1 on with the [GitHub CLI](https://cli.github.com/)
(1.1.0 has provenance for its DMG only):

```bash
gh attestation verify DoppelDock.dmg -R ZarinLab/doppeldock
gh attestation verify doppeldock-1.2.3.tar.gz -R ZarinLab/doppeldock   # source archive
gh attestation verify doppeldock -R ZarinLab/doppeldock                 # the script itself
```

From 1.1.1, each release also has `SHA256SUMS` with the files' checksums and
the signed provenance bundle (`doppeldock-X.Y.Z.intoto.jsonl`), which
`gh attestation verify --bundle` checks without fetching the provenance from
GitHub (it still uses Sigstore's public trust root). Homebrew installs the same
attested source archive, and the Terminal install line downloads the released
script.

## How the project is protected

- Secret scanning with push protection, and Dependabot alerts.
- CodeQL code scanning of the GitHub Actions workflows, and
  [zizmor](https://docs.zizmor.sh/) and actionlint on every change.
- Every action pinned to a full commit hash; Dependabot proposes updates only
  after they have been out for two weeks.
- Workflows run with the least permissions they need.
- `main` can't be force-pushed or deleted; pull requests need passing CI, and
  CI also runs on every push to `main`.
- A weekly [OpenSSF Scorecard](https://scorecard.dev/viewer/?uri=github.com/ZarinLab/doppeldock) check, and the [OpenSSF Best Practices badge](https://www.bestpractices.dev/projects/16924).
