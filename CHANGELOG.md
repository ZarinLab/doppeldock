# Changelog

All notable changes to DoppelDock are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- The website has a sitemap, fuller structured data (including its questions
  and answers) and an `llms.txt` summary, so search engines and other tools can
  describe DoppelDock accurately. `tests/site_checks.js` keeps them in step
  with the page and the version.

## [1.1.2] - 2026-11-19

### Changed

- The Mac app no longer uses APIs Apple has deprecated: choosing an app uses
  content types, the app activates with the current call on macOS 14 and later
  (and its window is brought to the front), and colour dots are drawn without
  `lockFocus`.

### Added

- Automated checks of the Mac app's own code (`tests/gui_checks.js`): every app
  in the App list can be chosen (including one added with Other…), Other… offers
  only apps, labels are right-aligned, colour dots are drawn.
  They are regression tests for the two Mac app fixes in 1.1.1.

## [1.1.1] - 2026-11-19

### Added

- About DoppelDock (the "?" button, or DoppelDock › About DoppelDock) shows the
  version, the unofficial-tool notice and a link to the website. The release
  notes carry the same notice.
- Releases now include the script and a source archive alongside the DMG, with
  `SHA256SUMS` and signed build provenance for all of them (verify with
  `gh attestation verify`). Homebrew installs the attested source archive.
- Governance, roadmap, architecture and security model documents, and a
  documented vulnerability response process.
- Developer Certificate of Origin sign-off for contributions, checked on every
  pull request.
- Test coverage measured in CI (at least 80% of the script's shell statements),
  and many more tests (menu, options, colours, refusals).
- `shfmt` code style, enforced in CI; `Brewfile` and `Gemfile` list the
  development tools.
- The website sets a Content Security Policy.
- `DOPPELDOCK_APPS_DIR` chooses another folder for new apps and adds it to
  where DoppelDock looks for profiles.
- The Terminal install line downloads the released, attested script instead of
  the latest code on `main`.

### Changed

- The script is reformatted with `shfmt` (layout only, no behaviour change).

### Fixed

- Apps in the New Profile window's App list were greyed out and could not be
  chosen (only Other… worked).
- On Apple silicon Macs, the form's labels were centred instead of
  right-aligned.

## [1.1.0] - 2026-11-19

### Added

- **Download:** each release now has `DoppelDock.dmg` with the app, an
  Applications shortcut and a note on opening it the first time (it isn't
  notarized by Apple). It is built automatically when a version is tagged.
- **Homebrew:** `brew install zarinlab/tap/doppeldock`.
- **Website:** <https://zarinlab.github.io/doppeldock/>.

### Fixed

- Own icon profiles made with a Homebrew install keep updating after
  `brew upgrade` (they now use Homebrew's stable path).

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
- Contributing guide, code of conduct, security policy, and issue and pull
  request templates.
- Tests (`tests/smoke.sh`) and CI on GitHub Actions: shellcheck, macOS bash 3.2
  syntax, compile checks for the built-in JavaScript, and building, changing
  and removing profiles from Electron's sample app.

[Unreleased]: https://github.com/ZarinLab/doppeldock/compare/v1.1.2...HEAD
[1.1.2]: https://github.com/ZarinLab/doppeldock/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/ZarinLab/doppeldock/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/ZarinLab/doppeldock/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/ZarinLab/doppeldock/releases/tag/v1.0.0
