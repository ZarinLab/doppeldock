# Roadmap

What DoppelDock intends to do, and not do, over the next year (to the end of
2027). Plans can change; changes are discussed in issues and recorded here.

## Planned

- **Keep up with macOS and the apps.** Test new macOS releases and new versions
  of popular Electron apps, and fix what breaks. Replace tools Apple deprecates
  (for example `hdiutil` in favour of `diskutil image`) once the supported
  macOS versions all have the replacement.
- **More tests.** Keep statement coverage of the script's shell code at 80% or
  more, and add automated checks for the Mac app's windows where practical.
- **A notarized download.** If an Apple Developer ID becomes available, sign
  and notarize `DoppelDock.app` in the release workflow so the DMG opens
  without the "Open Anyway" step.
- **Smoother updates.** Let the Mac app tell you when a newer DoppelDock
  release is available.
- **Accessibility and wording.** Review the app with VoiceOver and keyboard-only
  use, and keep the wording plain.

## Considered, not committed

- Translating the Mac app's text into other languages, if people ask for it.
- A "profile per space" option that opens a profile on a chosen macOS desktop.

## Not planned

- **Other operating systems.** DoppelDock is macOS-only.
- **Apps that aren't built on Electron.** Chromium-based browsers already have
  their own profiles, and other apps don't share Electron's data-folder design.
- **Changing apps beyond what's described.** DoppelDock will not patch an app's
  code, inject into it or bypass its licence checks. The own icon option only
  re-signs a copy, as documented in [docs/details.md](docs/details.md).
- **Collecting data.** DoppelDock makes no network connections of its own and
  will not add analytics.
