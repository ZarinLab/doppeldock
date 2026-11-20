# Architecture

[← Back to the README](../README.md) · See also [details](details.md) and the [security model](security.md).

DoppelDock is one Bash script, `doppeldock`, that runs on macOS with the
built-in `/bin/bash` 3.2 and Apple's own command-line tools. Everything else is
generated from it.

```
                         ┌──────────────────────────────┐
  Terminal / Homebrew ──►│  doppeldock (Bash script)    │◄── DoppelDock.app
                         │  new · change · rebuild ·    │    (Mac app: JavaScript for
                         │  remove · list · install     │     Automation; bundles a copy
                         └──────────────┬───────────────┘     of the script, calls it)
                                        │ builds
             ┌──────────────────────────┴──────────────────────────┐
             ▼                                                     ▼
  "<App> <Name>.app"  launcher mode                    "<App> <Name>.app"  copy mode
  small app; its wrapper runs                          APFS clone of the app; its wrapper runs
  open -n -a <original app> --args                     <copy>/Contents/MacOS/<exe>
     --user-data-dir=<data folder>                        --user-data-dir=<data folder>
                                                       (rebuilds itself after the original updates)
             │                                                     │
             └────────────────────┬────────────────────────────────┘
                                  ▼
          ~/Library/Application Support/DoppelDock/<app id>/<name>/   (the profile's data)
          contains .doppeldock-profile (marker with the profile's bundle ID)
```

## Components

| Component | Where | What it does |
|---|---|---|
| **The script** | `doppeldock` | All logic: argument parsing, validation, building, changing, rebuilding and removing profiles, the Terminal menu, and `install`. |
| **Profile app, launcher mode** | `/Applications/<App> <Name>.app` | A minimal app bundle whose executable is a generated wrapper script. It brings an already running profile to the front, or opens the original app with `--user-data-dir`. The original app is not modified. |
| **Profile app, copy mode** | `/Applications/<App> <Name>.app` | An APFS clone of the original app with its own bundle ID, name and icon; the main binary is re-signed ad hoc; the executable is a wrapper that always passes `--user-data-dir` and rebuilds the copy when the original app's version changes. |
| **Wrapper scripts** | inside each profile app | Written by `write_launcher_wrapper` / `write_copy_wrapper`. All values are written with `printf %q`, then fixed code from a quoted heredoc. |
| **Icons** | `make_icon`, `make_doppeldock_icon` | Drawn with AppKit through `osascript -l JavaScript`, then converted with `sips` and `iconutil`. |
| **DoppelDock.app** | `/Applications/DoppelDock.app` | Built by `doppeldock install` with `osacompile`: a stay-open JavaScript for Automation applet (window, New Profile and Edit form, Remove alert). It runs the bundled script through `/bin/bash` for every action. |
| **Profile metadata** | `Info.plist` keys `DoppelDock*` | Source app, label, mode, colour, style, appearance, data folder, versions. `change` and `rebuild` read them back. |
| **Data folder marker** | `<data folder>/.doppeldock-profile` | Holds the profile's bundle ID. DoppelDock only deletes (moves to the Trash) a data folder whose marker matches. |

## Main flows

- **new**: validate inputs → check nothing would be overwritten and nothing is
  running → draw the icon → build the bundle in a work folder next to the
  target → sign → write the marker → swap it into place (moving any old copy
  aside so it can be restored) → register with Launch Services.
- **change / rebuild**: read the profile's `DoppelDock*` keys, apply any new
  options, and run the same build in place. App, name and data folder never
  change.
- **remove**: check the app is a DoppelDock profile with a valid bundle ID and
  not running → move it to the Trash → delete its small macOS preferences and
  caches → with `--delete-data`, move the data folder to the Trash only if its
  marker matches.
- **install**: compile the applet, copy the script into it, draw its icon,
  sign, and swap it into place.

## Build, test and release

| What | Where |
|---|---|
| Tests | `tests/smoke.sh` (static checks, checks of the Mac app's forms in `tests/gui_checks.js`, checks of the website's structured data in `tests/site_checks.js`, and end-to-end profile tests), `tests/coverage.sh` (statement coverage with bashcov) |
| CI | `.github/workflows/ci.yml`: lint and code style, workflow security, tests and coverage on macOS, DMG build |
| Release | `.github/workflows/release.yml`: on a `vX.Y.Z` tag, builds the DMG and the source archive, records signed build provenance and publishes the GitHub release |
| Website | `site/` published by `.github/workflows/pages.yml` |
| Homebrew | [ZarinLab/homebrew-tap](https://github.com/ZarinLab/homebrew-tap) updates its formula from the latest release |
