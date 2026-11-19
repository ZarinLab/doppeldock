# Security model and assurance case

[← Back to the README](../README.md) · How to report a problem: [SECURITY.md](../SECURITY.md)

## What you can expect (security requirements)

DoppelDock is designed so that:

1. **It never changes or deletes the original app.** It only reads it (to clone
   it or open it).
2. **It only replaces or removes apps it made**, for the same profile, and never
   while the profile is running.
3. **It never permanently deletes a profile's app or data folder.** Removing a
   profile moves its app, and only if you ask, its data folder, to the Trash. A
   data folder is only moved if it carries the profile's own marker. The
   profile's small macOS preferences, caches, saved window positions and its
   DoppelDock log are deleted.
4. **Profiles are kept apart.** Each profile uses its own data folder for the
   app's sign-in, settings and local data. DoppelDock refuses a folder that a
   running app was started with (`--user-data-dir`); it can't see other uses.
5. **It treats names, paths and app metadata as untrusted** and rejects
   anything outside what it expects.
6. **It makes no network connections of its own** and collects no data.
7. **What you install is what was released** (from 1.1.1): the DMG, the
   Homebrew formula and the Terminal install line all use released files, which
   carry signed build provenance and checksums and are served over HTTPS.

What it does **not** promise:

- **An own icon copy is less protected than the original app.** It is signed on
  your Mac instead of by the app's maker, without the maker's team ID, and
  accepts code libraries not signed by the maker (needed to load the maker's own
  frameworks). It keeps macOS's hardened runtime.
- **Separation is limited to the app's data folder.** Anything an app keeps
  elsewhere in your home folder, its keychain item ("*App* Safe Storage") and its
  log folder are shared between the original and its profiles.
- **The DMG isn't notarized by Apple.** Verify it as described in
  [SECURITY.md](../SECURITY.md).
- DoppelDock can't make an app more secure than it is, or protect against
  malware already running as your user.

## Assurance case

This section argues why the requirements above are met.

### Threat model

| Asset | Threats |
|---|---|
| Your apps (the original app, other apps in Applications) | Being overwritten, deleted or modified by mistake or through crafted input |
| Profile data (sign-ins, settings) | Being deleted, mixed up between profiles, or corrupted by two processes |
| Your system and account | Command injection through crafted names or app metadata; unsafe temporary files; running tampered code from a download |
| The project's releases and CI | Supply-chain attacks: a compromised dependency or action, workflow injection, leaked credentials |

Attackers considered: **crafted input** (a malicious app bundle's
`Info.plist`, an odd profile name or path); **another local user** on a shared
Mac (temporary files, the install path); **a network attacker** (downloads);
**a compromised third-party component** in CI. Out of scope: malware already
running as the same user, and a compromised macOS or Apple toolchain.

### Trust boundaries

1. **You → DoppelDock**: command-line options, the Mac app's form, dragged paths.
2. **DoppelDock → the file system**: the original app (read only), the install
   folder, data folders, the Trash.
3. **The source app's bundle → DoppelDock**: `Info.plist` values and
   entitlements are data from another vendor.
4. **The Internet → your Mac**: the install line, the DMG, Homebrew.
5. **GitHub Actions → releases**: third-party actions and the release workflow.

### Secure design principles applied

| Principle | How |
|---|---|
| Economy of mechanism | One script, Apple's own tools only, no runtime dependencies. |
| Fail-safe defaults | Refuse when unsure (unknown app, existing folder, running profile); removals go to the Trash; the data folder is kept unless you ask. |
| Complete mediation | Every command re-checks ownership (bundle ID, `DoppelDock*` keys, data marker) and running state right before acting, including just before the final swap. |
| Least privilege | Runs as you, never with `sudo`; CI jobs get only the permissions they need; checkouts keep no credentials unless a job must push. |
| Open design | Everything is in this public repository; releases are built by public workflows. |
| Separation of privilege | Ownership needs both the bundle ID pattern and the profile keys; data deletion also needs the marker. |
| Least common mechanism | Each profile has its own app, bundle ID and data folder. |
| Psychological acceptability | Plain words throughout; the trade-offs of the own icon option are explained right under its checkbox (and before the copy is made in the Terminal menu); removals default to keeping the data. |
| Input validation | Modes, styles, appearances, colours and bundle IDs are checked against allow-lists or strict patterns; profile names and badges by length and forbidden characters; paths are resolved and checked. |

### Common weaknesses and how they are countered

| Weakness | Countermeasure |
|---|---|
| Path traversal (CWE-22) | Profile names can't contain `/`, `:`, control characters or start with `.`; data folders must be absolute without `.`/`..`; paths are resolved before use. |
| OS command injection (CWE-78) | Every expansion is quoted; values written into generated scripts go through `printf %q`; the Mac app passes arguments with shell quoting; no `eval`. |
| Insecure temporary files (CWE-377) | Work folders come from `mktemp -d` in the target folder; the install line downloads into a per-user `mktemp -d` folder. |
| Race conditions (CWE-367) | Running-state checks are repeated just before replacing an app; the old app is moved aside and restored if the swap fails or is interrupted. |
| Deleting the wrong data (CWE-73, CWE-1188) | Marker check before moving a data folder; refusal of folders that already hold someone else's data. |
| Download without integrity check (CWE-494) | HTTPS only; from 1.1.1, checksums and signed build provenance for every release file, and all install methods use release files; the copy rebuild uses the installed script, never a temporary download. |
| Supply chain (CWE-829, CWE-1357) | Actions pinned to commit hashes, two-week cooldown on updates, zizmor and CodeQL on workflows, bashcov pinned with checksums and Electron's test app pinned to an exact version. |
| Leaked credentials (CWE-798) | No secrets in the repository; GitHub secret scanning with push protection. |

### Evidence

- Tests: `tests/smoke.sh` (refusals, signatures, data handling), with at least
  80% of the script's shell statements covered, measured in CI
  (`tests/coverage.sh`). The embedded JavaScript of the Mac app is
  compile-checked, its forms are partly checked by `tests/gui_checks.js`, and its
  windows are also tested by hand.
- Static analysis on every change: shellcheck, shfmt, actionlint and zizmor in
  CI (results in the CI logs), and CodeQL (results in the Security tab).
- The maintainer reviews security-relevant changes against this document
  before each release, with the help of automated review tools.
- Weekly [OpenSSF Scorecard](https://scorecard.dev/viewer/?uri=github.com/ZarinLab/doppeldock)
  and the [OpenSSF Best Practices badge](https://www.bestpractices.dev/projects/16924).
