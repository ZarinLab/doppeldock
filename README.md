# DoppelDock

Use a second account in an app on your Mac, side by side with your usual one.
For example your personal Slack next to your work Slack, each in its own
window, with its own sign-in and its own coloured icon.

DoppelDock works with apps built on Electron, such as Slack, Discord, Visual
Studio Code, Figma, Signal and draw.io. It needs nothing besides macOS 12 or
later; it has been tested on macOS 27 on Apple silicon.

> **Unofficial.** DoppelDock is not affiliated with, endorsed by or supported by
> the makers of any app it works with. App names are trademarks of their owners.
> Check each app's terms of use before using it, especially the **own icon**
> option, which makes a modified copy of the app. You are responsible for how
> you use this tool.

## Get started

1. Open **Terminal** (in Applications › Utilities), paste this line and press Return:

   ```bash
   d=$(mktemp -d) && curl -fsSL https://raw.githubusercontent.com/ZarinLab/doppeldock/main/doppeldock -o "$d/doppeldock" && bash "$d/doppeldock" install
   ```

   This puts the **DoppelDock** app in your Applications folder. You only need
   Terminal this once.

2. Open **DoppelDock** from your Applications folder. It shows your profiles;
   click **New Profile…** and fill in one short form:
   - **App:** the app you want a second copy of,
   - **Name:** for example *Personal* or *Work*,
   - **Colour** and **Style:** colour and letter badge, colour only, or a
     badge on the app's original colours (a preview shows how it will look),
   - **Appearance:** same as the Mac, or always Light or always Dark, so the
     two windows look different too (see below),
   - **Show its own icon in the Dock while it is open:** on by default (see
     below).

3. Open the new app (for example **Slack Personal**), sign in with your other
   account, and keep it in the Dock: right-click its icon while it is open and
   choose **Options › Keep in Dock**.

Open DoppelDock again at any time to add more profiles, or select one to
**Open**, **Edit** or **Remove** it. **Edit…** changes a profile's colour,
style, appearance and whether it has its own Dock icon; its app, name, sign-in
and settings stay as they are. Saving also brings it up to date with the
original app.

## Same icon or own icon?

DoppelDock always gives the new app its own icon (recoloured, with a letter
badge, or both), so you can tell it apart in your Applications folder and in
the Dock. The choice is about what the Dock shows **while it is open**:

| | **Own icon** (box ticked) | **Same icon** (box unticked) |
|---|---|---|
| While open, the Dock shows | the coloured icon and the profile name | the app's normal icon |
| The original app | untouched | untouched |
| How it works | makes a separate copy of the app and signs it on your Mac | opens the original app with its own data folder; nothing is modified |
| Updates | the copy updates itself from the original the next time you open it | always the current version |

**Own icon** needs a copy because macOS takes the icon of a running app from
the app itself. Things to know about it:

- macOS may ask again for permissions such as camera or microphone, and
  whether the copy may use the app's keychain item ("*App* Safe Storage").
  Choose **Always Allow**. This can happen again after the copy updates itself.
- A few features of the app may not work in the copy.
- Don't use the copy's own "Check for updates"; update the original app instead.
- The menu bar still shows the original app's name.
- The copy is signed on your Mac instead of by the app's maker, so it is less
  protected against other programs on your Mac changing it.

## Telling the windows apart

DoppelDock can't recolour another app's windows, but it can open a profile in
**Light** or **Dark** whatever your Mac is set to, for example your work copy
in Dark and your personal copy in Light. This works for apps that follow the
Mac's appearance; if the app has its own theme setting set to Light or Dark,
that setting wins. Many apps also let you pick a theme per profile in their own
settings, because each profile keeps its own settings.

## What is shared and what is separate

Separate: everything the app keeps in its data folder, which for Electron apps
means the sign-in, settings, caches and local data.

Shared: anything the app keeps elsewhere in your home folder (for example
`~/.config/...`), and macOS-level things such as the app's keychain item and
log folder.

## Safety

- DoppelDock never changes the original app, and only replaces or removes apps
  it made itself.
- It won't update or remove a profile while it is open, and won't build a
  profile onto a data folder another running app is using.
- Removing a profile moves its app to the Trash. Its sign-in and settings stay
  unless you choose to delete them; then its data folder goes to the Trash too,
  and only if DoppelDock created it for that profile. Its small macOS
  preferences, caches and saved window positions are deleted.
- Opening a profile that is already open brings its window to the front.

## Where things live

| What | Where |
|---|---|
| DoppelDock | `/Applications/DoppelDock.app` |
| Each profile | `/Applications/<App> <Name>.app` |
| Each profile's data | `~/Library/Application Support/DoppelDock/<app-id>/<name>/` |
| Update log (own icon) | `~/Library/Logs/DoppelDock/` |

If `/Applications` is not writable for your account, DoppelDock uses
`~/Applications` instead.

## Uninstall

In DoppelDock, select each profile and click **Remove…** (tick **Also delete
this profile's sign-in and settings** to remove those too). Removed apps and
data go to the Trash. Then move `DoppelDock.app` to the Trash.
Profile data you kept is in `~/Library/Application Support/DoppelDock`.

## Advanced: command line

The `doppeldock` script does everything the app does, and more. Run it without
arguments for a menu, or use commands:

```bash
git clone https://github.com/ZarinLab/doppeldock.git && cd doppeldock

./doppeldock                                   # menu
./doppeldock install [--dir DIR]               # install the DoppelDock app
./doppeldock new --app /Applications/Slack.app --name Personal               # same icon
./doppeldock new --app /Applications/Slack.app --name Personal --mode copy   # own icon
./doppeldock list
./doppeldock change  "/Applications/Slack Personal.app" --appearance light --color blue
./doppeldock rebuild "/Applications/Slack Personal.app" [--adopt-data-dir]
./doppeldock remove  "/Applications/Slack Personal.app" [--delete-data]
```

Options for `new`:

| Option | Meaning |
|---|---|
| `--mode launcher\|copy` | Same icon (default) or own icon |
| `--color` | green, blue, purple, pink, orange, teal, red, gray or `#RRGGBB` |
| `--badge` | One or two characters (default: first letter of the name) |
| `--style` | `tint+badge` (default), `tint` (colour only) or `badge` (badge on the original colours) |
| `--appearance` | `system` (default), `light` or `dark`; passed to the app as the Chromium switches `--blink-settings=preferredColorScheme=1` or `--force-dark-mode` |
| `--data-dir DIR` | Use another data folder than the default |
| `--adopt-data-dir` | Allow `--data-dir` to point at a folder that already has data DoppelDock did not create, for example to keep an existing sign-in. That folder is then treated as the profile's own, so `remove --delete-data` deletes it. Never adopt the original app's own data folder: both would use it at the same time |
| `--install-dir DIR` | Where to put the app |
| `--yes` | Skip the own-icon confirmation |

### How the own-icon copy is made

The copy is an APFS clone of the app (almost no extra disk space on the same
volume). DoppelDock changes its bundle ID, display name and icon, removes its
URL schemes and file types (so links and files keep opening in the original),
and replaces its executable with a small wrapper that always passes
`--user-data-dir`. It re-signs the main binary ad hoc, keeping the hardened
runtime but without the entitlements that only work with the maker's signature
(team ID, application ID, keychain access groups, app groups). Because the copy
no longer has the maker's team ID, it adds `disable-library-validation` so it
can load the maker's own frameworks, which means the copy's main process
accepts libraries not signed by the maker. If the app allows `DYLD_*`
environment variables, the copy drops that permission.

## Limitations

- Electron apps only. Chromium-based browsers already have profiles.
- Apps that check their own code signature may refuse to run as an own-icon copy.
- Signing in through a browser (for example "Sign in with Google") may send you
  back to the original app, because the copy does not handle the app's links.
  Use the app's own sign-in (email code or password) where you can.
- Profile names must not contain `/`, `:` or control characters, must not start
  with `.`, and are at most 40 characters.

## Related

- [doppel-app](https://github.com/dotrg-31/doppel-app) does the same for the
  ChatGPT desktop app on macOS and Windows.

## Licence

MIT, see [LICENSE](LICENSE).
