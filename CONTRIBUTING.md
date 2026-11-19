# Contributing to DoppelDock

Thanks for helping! Bug reports, ideas and pull requests are all welcome.

- **Bugs and ideas:** open an [issue](https://github.com/ZarinLab/doppeldock/issues/new/choose).
- **Security problems:** report them privately, see [SECURITY.md](SECURITY.md).
- **Everyone** is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
- **Who decides what:** see [GOVERNANCE.md](GOVERNANCE.md); where the project
  is heading: [ROADMAP.md](ROADMAP.md).

## How the project is laid out

| Path | What it is |
|---|---|
| `doppeldock` | The whole tool: one Bash script. It also contains the Mac app (JavaScript for Automation, in `write_gui_script`) and the icon drawing code |
| `tests/smoke.sh` | Tests: static checks, plus building, changing and removing profiles from an Electron app |
| `tests/coverage.sh` | Statement coverage of the script's shell code (bashcov; the embedded JavaScript is only compile-checked); CI requires at least 80% |
| `tools/make-dmg.sh` | Builds `DoppelDock.dmg` |
| `docs/` | [details](docs/details.md) (reference), [architecture](docs/architecture.md), [security model](docs/security.md), and the README's images |
| `site/` | The website |
| `.github/` | CI, release and site workflows, issue and pull request templates, Dependabot |

## Setting up

You need a Mac. Everything else for development is listed in `Brewfile`
(Homebrew) and `Gemfile` (Ruby):

```bash
git clone https://github.com/ZarinLab/doppeldock.git && cd doppeldock
brew bundle        # shellcheck, shfmt, a newer bash, Ruby, Node
bundle install     # bashcov, for test coverage
tests/smoke.sh     # static checks
```

## Ground rules

These keep DoppelDock safe and installable on any Mac:

- **macOS only, nothing to install.** At run time, use only tools that ship
  with macOS (`/usr/bin`, `/bin`, `osascript`, `codesign`, `sips`, `iconutil`,
  `plutil`...). No Homebrew, Python, Node or Xcode at run time.
- **Bash 3.2.** The script runs with macOS's `/bin/bash`, which is version 3.2:
  no associative arrays, `mapfile`, `${var,,}` and so on. Check with
  `/bin/bash -n doppeldock`.
- **Never destroy user data.** Removals go to the Trash. Never touch the
  original app, and only replace or remove apps DoppelDock made itself (check
  the bundle ID and the `DoppelDock*` keys). Refuse to work on a profile that
  is running. See the [security model](docs/security.md).
- **Validate input with allow-lists.** Treat names, paths and other apps'
  `Info.plist` values as untrusted.
- **Quote everything.** Paths contain spaces. Values written into generated
  scripts go through `printf %q` (see `write_vars`). Never use `eval`.
- **No app makers' logos** in screenshots or other images in this repo. Use
  open-source apps such as draw.io or Bruno for demos.
- **Workflows:** pin every action to a full commit hash with the version in a
  comment (`uses: owner/action@<sha> # vX.Y.Z`), use releases that are at least
  two weeks old, give each job only the permissions it needs, and set
  `persist-credentials: false` on checkout unless the job pushes.
- **Keep it understandable.** Plain words in the app and the README; technical
  detail goes in `docs/`.

## Coding standards

| Language | Style guide | Enforced by (in CI) |
|---|---|---|
| Bash (`doppeldock`, `tests/`, `tools/`) | [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html), adapted for Bash 3.2 and with two-space indentation | `shfmt` (layout, settings in `.editorconfig`) and `shellcheck` (correctness) |
| GitHub Actions workflows | [GitHub's security hardening guide](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions) | `actionlint` and `zizmor` |
| JavaScript for Automation (inside the script) | Follow the existing style: ES5-compatible, `var`, two-space indentation | Compiled with `osacompile` by `tests/smoke.sh` |

Contributions must follow these. Check locally before pushing:

```bash
shfmt -d doppeldock tests/*.sh tools/*.sh
shellcheck -s bash -S warning doppeldock tests/*.sh tools/*.sh
uvx --from actionlint-py actionlint && uvx zizmor --offline .
```

### Notes on the Mac app (JavaScript for Automation)

- Values coming back from AppKit (`state`, `indexOfSelectedItem`,
  `runModal`...) are objects: wrap them in `Number(...)` before comparing.
- Pass `$()` for `nil`, not `null`, when setting a property.
- `NSPopUpButton addItemWithTitle:` drops items with the same title; add
  `NSMenuItem`s to the menu instead.

## Tests

**Test policy.** Every change that adds or changes behaviour **must** add or
update tests in `tests/smoke.sh` in the same pull request. Every bug fix
**must** add a regression test, unless the bug can't be reproduced
automatically (for example a window layout); then say so in the pull request.
Statement coverage of the script's shell code must stay at 80% or more; CI
checks this (`tests/coverage.sh`).

Static checks only (syntax, shellcheck, shfmt-clean code, JavaScript compiles):

```bash
tests/smoke.sh
```

Full tests need an Electron app. Any installed one works, for example
`tests/smoke.sh /Applications/draw.io.app`. To use the same app as CI:

```bash
d=$(mktemp -d) && (cd "$d" && npm init -y >/dev/null && npm install --no-audit --no-fund electron@33.4.11)
codesign --force --deep -s - "$d/node_modules/electron/dist/Electron.app"
tests/smoke.sh "$d/node_modules/electron/dist/Electron.app"
bundle exec tests/coverage.sh "$d/node_modules/electron/dist/Electron.app"   # coverage
```

The tests build profiles in a temporary folder and never launch anything. The
apps and data they remove at the end go to your Trash.

Changes to the Mac app's windows also need a look by hand: run
`./doppeldock install --dir ~/Applications/DoppelDock-test` and open that copy.

## Developer Certificate of Origin

Every commit must be signed off, certifying the
[Developer Certificate of Origin 1.1](https://developercertificate.org/): that
you wrote the change or otherwise have the right to submit it under the
project's MIT licence. Add the sign-off with `git commit -s`, which appends:

```
Signed-off-by: Your Name <your.email@example.com>
```

The name and email must match the commit's author. A check on every pull
request enforces this. Forgot? Run `git commit --amend -s` (one commit) or
`git rebase --signoff main` (several), then push again.

## Pull requests

1. Fork the repository and create a branch from `main`.
2. Make your change; keep pull requests focused on one thing.
3. Add or update tests (see the test policy) and run them with an Electron app.
4. Update `README.md` or `docs/` if behaviour changed, and add a line to
   `CHANGELOG.md` under **Unreleased**.
5. Sign off every commit, open the pull request and fill in the template. CI
   must pass, and the maintainer reviews every pull request before merging.

Commit messages: a short summary line in the imperative ("Add …", "Fix …"),
then a blank line and the why, if it isn't obvious.

## Releasing (maintainers)

1. Set `VERSION` at the top of `doppeldock`.
2. Move the **Unreleased** notes in `CHANGELOG.md` under the new version and date.
3. Commit and push, and wait for CI to pass.
4. Tag `vX.Y.Z` and push the tag. The **Release** workflow checks the tag
   matches `VERSION`; builds `DoppelDock.dmg`, the script and a source archive;
   records signed build provenance for them; and publishes the GitHub release
   with the changelog notes, `SHA256SUMS` and the provenance bundle.
5. The Homebrew formula in
   [ZarinLab/homebrew-tap](https://github.com/ZarinLab/homebrew-tap) updates
   itself within 6 hours (tested before it is committed). To do it at once, run
   its **Update formulae** workflow from the Actions tab.

By contributing, you agree that your contributions are licensed under the
[MIT licence](LICENSE).
