# Changelog

All notable changes to DoppelDock are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Contributing guide, code of conduct, security policy and issue and pull
  request templates.
- Tests (`tests/smoke.sh`) and CI on GitHub Actions: shellcheck, macOS bash 3.2
  syntax, compile checks for the built-in JavaScript, and building, changing
  and removing profiles from Electron's sample app.

## [1.0.0] - 2026-11-19

First public version.

### Added

- **DoppelDock app** with a list of your profiles and **New Profile…**,
  **Edit…**, **Open** and **Remove…**.
- Profiles that open the original app with their own data folder, or run as a
  re-signed copy with their own Dock icon and name.
- Icon colour and style (colour and badge, colour only, badge only), with a
  live preview.
- **Appearance** per profile: same as the Mac, always Light or always Dark.
- Own icon copies rebuild themselves from the original app after it updates.
- Removing a profile moves it to the Trash; its sign-in is kept unless you
  choose to delete it.
- `doppeldock` command line: `install`, `new`, `change`, `rebuild`, `remove`,
  `list`, and a menu.

[Unreleased]: https://github.com/ZarinLab/doppeldock/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/ZarinLab/doppeldock/releases/tag/v1.0.0
