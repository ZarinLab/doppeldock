# DoppelDock: details and command line

[← Back to the README](../README.md)

- [How it works](#how-it-works)
- [Where things live](#where-things-live)
- [Safety checks](#safety-checks)
- [Command line](#command-line)
- [How the own icon copy is made](#how-the-own-icon-copy-is-made)
- [Appearance](#appearance)
- [Limitations](#limitations)

## How it works

Electron apps keep their sign-in, settings and caches in one data folder, and
accept `--user-data-dir` to use another. A DoppelDock profile is a small app
that starts the real app with its own folder, so the two never share that data.

| | Own icon (box ticked) | Same icon (box unticked) |
|---|---|---|
| What DoppelDock builds | A copy of the app with its own name, icon and data folder | A small app that opens the original with its own data folder |
| While open, the Dock shows | The coloured icon and the profile name | The app's normal icon |
| The original app | Untouched | Untouched |
| Updates | The copy rebuilds itself from the original the next time you open it | Always the current version |

The own icon option needs a copy because macOS takes a running app's icon from
the app itself.

## Where things live

| What | Where |
|---|---|
| DoppelDock | `/Applications/DoppelDock.app` (the script is bundled in `Contents/Resources`) |
| Each profile | `/Applications/<App> <Name>.app` |
| Each profile's data | `~/Library/Application Support/DoppelDock/<app-id>/<name>/` |
| Update log (own icon) | `~/Library/Logs/DoppelDock/` |

If `/Applications` is not writable for your account, `~/Applications` is used.

## Safety checks

- DoppelDock never changes the original app, and only replaces or removes apps
  it made itself.
- It won't build, change or remove a profile while it is open, or build one
  onto a data folder another running app is using.
- It refuses a data folder that already has data unless DoppelDock created it
  for the same profile (it carries a `.doppeldock-profile` marker), or you pass
  `--adopt-data-dir`.
- Removing a profile moves its app to the Trash. With **Also delete…** (or
  `--delete-data`) its data folder goes to the Trash too, but only if it carries
  the profile's marker. Its small macOS preferences, caches and saved window
  positions are deleted.
- Opening a profile that is already open brings its window to the front instead
  of starting a second process on the same data folder.

## Command line

The `doppeldock` script does everything the app does. Run it without arguments
for a menu, or use commands:

```bash
git clone https://github.com/ZarinLab/doppeldock.git && cd doppeldock

./doppeldock                         # menu
./doppeldock install [--dir DIR]     # install the DoppelDock app
./doppeldock new --app /Applications/Slack.app --name Personal               # same icon
./doppeldock new --app /Applications/Slack.app --name Personal --mode copy   # own icon
./doppeldock list
./doppeldock change  "/Applications/Slack Personal.app" --appearance light --color blue
./doppeldock rebuild "/Applications/Slack Personal.app" [--adopt-data-dir]
./doppeldock remove  "/Applications/Slack Personal.app" [--delete-data]
```

Options for `new` (and, where it makes sense, `change`):

| Option | Meaning |
|---|---|
| `--mode launcher\|copy` | Same icon (default) or own icon |
| `--color` | green, blue, purple, pink, orange, teal, red, gray or `#RRGGBB` |
| `--style` | `tint+badge` (default), `tint` (colour only) or `badge` (badge on the original colours) |
| `--badge` | One or two characters (default: first letter of the name) |
| `--appearance` | `system` (default), `light` or `dark` |
| `--data-dir DIR` | Use another data folder than the default |
| `--adopt-data-dir` | Allow `--data-dir` to be a folder that already has data DoppelDock did not create, for example to keep an existing sign-in. It is then treated as the profile's own, so `remove --delete-data` moves it to the Trash. Never adopt the original app's own data folder: both would use it at once |
| `--install-dir DIR` | Where to put the app |
| `--yes` | Skip the own icon confirmation |

`change` keeps the app, name, sign-in and data, and rebuilds with the new
options; it also brings the profile up to date with the original app.

## How the own icon copy is made

- The copy is an APFS clone of the app, so it takes almost no extra disk space
  on the same volume.
- DoppelDock changes its bundle ID, display name and icon, and removes its URL
  schemes and file types, so links and files keep opening in the original.
- Its executable becomes a small wrapper that always passes `--user-data-dir`.
- The main binary is re-signed ad hoc, keeping the hardened runtime but without
  the entitlements that only work with the maker's signature (team ID,
  application ID, keychain access groups, app groups). Frameworks and helper
  apps keep the maker's signature.
- Because the copy no longer has the maker's team ID, it gets
  `disable-library-validation` so it can load the maker's frameworks; its main
  process then accepts libraries not signed by the maker. If the app allows
  `DYLD_*` environment variables, the copy drops that permission.
- `CFBundleName` stays as it is, because Electron finds its helper apps by that
  name; the menu bar therefore shows the original app's name.

## Appearance

**Light** and **Dark** start the app with the Chromium switch
`--blink-settings=preferredColorScheme=1` or `--force-dark-mode`. This works for
apps that follow the Mac's appearance; if an app's own theme setting is Light or
Dark, that setting wins. Each profile also keeps its own in-app theme setting.

## Limitations

- Electron apps only. Chromium-based browsers already have profiles.
- Apps that check their own code signature may refuse to run as an own icon copy.
- Signing in through a browser may return to the original app, because the
  copy does not handle the app's links.
- Profile names must not contain `/`, `:` or control characters, must not start
  with `.`, and are at most 40 characters.
- Tested on macOS 27 on Apple silicon.
