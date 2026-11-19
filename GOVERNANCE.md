# Governance

DoppelDock is a small open-source project run by its maintainer under the
[ZarinLab](https://github.com/ZarinLab) GitHub organisation. This page says who
decides what, and how the project keeps going if the maintainer can't.

## Roles

| Role | Who | Responsibilities |
|---|---|---|
| **Maintainer** | Amir Zarinbal ([@zarinbal](https://github.com/zarinbal)) | Sets direction and the [roadmap](ROADMAP.md); triages issues; reviews and merges pull requests; cuts releases; handles security reports under the [security policy](SECURITY.md); keeps the documentation, CI and the OpenSSF badge entries accurate; enforces the [Code of Conduct](CODE_OF_CONDUCT.md). |
| **Contributor** | Anyone who opens an issue or pull request | Follows [CONTRIBUTING.md](CONTRIBUTING.md), including the tests, coding standards and the Developer Certificate of Origin sign-off. |

The maintainer holds the owner role on the ZarinLab organisation and admin
rights on this repository and on
[ZarinLab/homebrew-tap](https://github.com/ZarinLab/homebrew-tap).

## How decisions are made

- Day-to-day decisions (accepting a change, the content of a release) are made
  by the maintainer, in the open, in the issue or pull request concerned.
- Larger changes (a new feature, a change in what DoppelDock modifies, a new
  dependency or distribution channel) start as an issue so they can be
  discussed before work begins.
- Security matters are handled privately first, as described in
  [SECURITY.md](SECURITY.md), and published once fixed.
- Pull requests need passing CI and are reviewed by the maintainer before
  merging. The maintainer's own changes go to `main` directly and are tested by
  CI on every push.

## Becoming a maintainer

Contributors who make sustained, high-quality contributions may be invited to
become maintainers. A new maintainer is added to this page and given the
access they need; the roles above are then shared between them.

## Continuity

DoppelDock must be able to continue (handle issues, accept changes and publish
releases) within a week if the maintainer becomes unable to continue.

- Planned, not yet in place: emergency access for a trusted person to the
  GitHub account that owns the ZarinLab organisation, so that person can keep
  the project running or hand it to a new maintainer. No passwords or keys are
  kept in this repository.
- Releases need no personal signing keys: they are built and signed by the
  [Release workflow](.github/workflows/release.yml) with GitHub's keyless
  signing, so anyone with access to the repository can publish one.
- Everything needed to build, test and release is in this repository and its
  CI, documented in [CONTRIBUTING.md](CONTRIBUTING.md).
