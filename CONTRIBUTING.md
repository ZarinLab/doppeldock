# Contributing to DoppelDock

Thanks for helping! Bug reports, ideas and pull requests are all welcome.

- **Bugs and ideas:** open an [issue](https://github.com/ZarinLab/doppeldock/issues/new/choose).
- **Security problems:** report them privately, see [SECURITY.md](SECURITY.md).
- **Everyone** is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## How the project is laid out

| Path | What it is |
|---|---|
| `doppeldock` | The whole tool: one Bash script. It also contains the Mac app (JavaScript for Automation, in `write_gui_script`) and the icon drawing code |
| `tests/smoke.sh` | Tests: static checks, plus building, changing and removing profiles from an Electron app |
| `docs/` | `details.md` (reference) and the README's images |
| `.github/` | CI, issue and pull request templates, Dependabot |

`doppeldock install` builds `DoppelDock.app` from the script with `osacompile`
and bundles a copy of the script inside it.

## Ground rules

These keep DoppelDock safe and installable on any Mac:

- **macOS only, nothing to install.** Use only tools that ship with macOS
  (`/usr/bin`, `/bin`, `osascript`, `codesign`, `sips`, `iconutil`, `plutil`...).
  No Homebrew, Python, Node or Xcode at run time.
- **Bash 3.2.** The script runs with macOS's `/bin/bash`, which is version 3.2:
  no associative arrays, `mapfile`, `${var,,}` and so on. Check with
  `/bin/bash -n doppeldock`.
- **Never destroy user data.** Removals go to the Trash. Never touch the
  original app, and only replace or remove apps DoppelDock made itself (check
  the bundle ID and the `DoppelDock*` keys). Refuse to work on a profile that
  is running.
- **Quote everything.** Paths contain spaces. Values written into generated
  scripts go through `printf %q` (see `write_vars`).
- **No app makers' logos** in screenshots or other images in this repo. Use
  open-source apps such as draw.io or Bruno for demos.
- **Keep it understandable.** Plain words in the app and the README; technical
  detail goes in `docs/details.md`.

### Notes on the Mac app (JavaScript for Automation)

- Values coming back from AppKit (`state`, `indexOfSelectedItem`,
  `runModal`...) are objects: wrap them in `Number(...)` before comparing.
- Pass `$()` for `nil`, not `null`, when setting a property.
- `NSPopUpButton addItemWithTitle:` drops items with the same title; add
  `NSMenuItem`s to the menu instead.
- After changing the app's code, check it compiles:
  `tests/smoke.sh` does this for every embedded JavaScript block.

## Running the tests

Static checks only (syntax, shellcheck if installed, JavaScript compiles):

```bash
tests/smoke.sh
```

Full tests need an Electron app. Any installed one works, for example
`tests/smoke.sh /Applications/draw.io.app`. To use the same app as CI:

```bash
d=$(mktemp -d) && (cd "$d" && npm init -y >/dev/null && npm install --no-audit --no-fund electron@33.4.11)
codesign --force --deep -s - "$d/node_modules/electron/dist/Electron.app"
tests/smoke.sh "$d/node_modules/electron/dist/Electron.app"
```

The tests build profiles in a temporary folder and never launch anything. The
apps and data they remove at the end go to your Trash.

Changes to the Mac app's windows also need a look by hand: run
`./doppeldock install --dir ~/Applications/DoppelDock-test` and open that copy.

## Pull requests

1. Fork the repository and create a branch from `main`.
2. Make your change; keep pull requests focused on one thing.
3. Run `tests/smoke.sh` with an Electron app, and add a test when you can.
4. Update `README.md` or `docs/details.md` if behaviour changed, and add a line
   to `CHANGELOG.md` under **Unreleased**.
5. Open the pull request and fill in the template. CI must pass.

Commit messages: a short summary line in the imperative ("Add …", "Fix …"),
then a blank line and the why, if it isn't obvious.

## Releasing (maintainers)

1. Set `VERSION` at the top of `doppeldock`.
2. Move the **Unreleased** notes in `CHANGELOG.md` under the new version and date.
3. Commit, tag `vX.Y.Z`, push the tag, and create a GitHub release from it with
   the changelog notes.

By contributing, you agree that your contributions are licensed under the
[MIT licence](LICENSE).
