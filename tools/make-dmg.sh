#!/bin/bash
# Build DoppelDock-<version>.dmg: the DoppelDock app, an Applications shortcut
# and a short "How to open" note, plus a .sha256 checksum file.
#
#   tools/make-dmg.sh [output-folder]      (default: dist/)
#
# Uses only tools that ship with macOS (hdiutil, shasum). The app is ad hoc
# signed, not notarized; the note explains macOS's one-time "Open Anyway" step.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/dist}"
VERSION="$(sed -n 's/^VERSION="\(.*\)"$/\1/p' "$ROOT/doppeldock")"
[[ -n "$VERSION" ]] || {
  echo "make-dmg: cannot read VERSION from doppeldock" >&2
  exit 1
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
STAGE="$WORK/DoppelDock"
mkdir -p "$STAGE" "$OUT"

/bin/bash "$ROOT/doppeldock" install --dir "$STAGE" >/dev/null
codesign --verify --deep --strict "$STAGE/DoppelDock.app"
ln -s /Applications "$STAGE/Applications"

cat >"$STAGE/How to open DoppelDock.txt" <<'TXT'
How to open DoppelDock

DoppelDock is a free, open-source tool and isn't notarized by Apple, so macOS
asks you to confirm it the first time:

1. Drag DoppelDock onto the Applications folder.
2. Open DoppelDock from Applications. When macOS says it can't verify it,
   click Done.
3. Open System Settings > Privacy & Security, scroll down, and click
   "Open Anyway" next to DoppelDock. Confirm with your password or Touch ID.

You only need to do this once.

Rather not see the warning? Install with Homebrew or the one-line Terminal
command instead: https://zarinlab.github.io/doppeldock/
TXT

DMG="$OUT/DoppelDock.dmg" # stable name: releases/latest/download/DoppelDock.dmg always works
rm -f "$DMG" "$DMG.sha256"
hdiutil create -volname "DoppelDock $VERSION" -srcfolder "$STAGE" -fs HFS+ -format UDZO -ov "$DMG" >/dev/null
hdiutil verify "$DMG" >/dev/null 2>&1
(cd "$OUT" && shasum -a 256 "$(basename "$DMG")" >"$(basename "$DMG").sha256")
echo "$DMG"
