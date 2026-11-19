#!/bin/bash
# DoppelDock smoke tests.
#
#   tests/smoke.sh [/path/to/Electron-based.app]
#
# Static checks always run. With an Electron app, it also builds, changes,
# rebuilds and removes profiles in a temporary folder (nothing is launched).
# Removed test apps and data go to your Trash.
#
# CI passes Electron's own sample app (npm package "electron", re-signed ad hoc).

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DD="$ROOT/doppeldock"
SRC="${1:-}"
PB=/usr/libexec/PlistBuddy
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok()   { pass=$((pass + 1)); printf '  ok    %s\n' "$1"; }
bad()  { fail=$((fail + 1)); printf '  FAIL  %s\n' "$1"; }
check() { # description, command...
  local d="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi
}
refuses() { # description, command... (must exit non-zero)
  local d="$1"; shift
  if "$@" >/dev/null 2>&1; then bad "$d (was accepted)"; else ok "$d"; fi
}
plist() { $PB -c "Print :$2" "$1/Contents/Info.plist" 2>/dev/null; }
equals() { # description, actual, expected
  if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (got '$2', expected '$3')"; fi
}

echo "Static checks"
check "syntax under macOS's /bin/bash" /bin/bash -n "$DD"
if command -v shellcheck >/dev/null; then
  check "shellcheck (warnings and errors)" shellcheck -s bash -S warning "$DD" "$0"
else
  echo "  skip  shellcheck (not installed)"
fi
check "help" /bin/bash "$DD" help
equals "version string" "$(/bin/bash "$DD" --version)" "DoppelDock $(sed -n 's/^VERSION="\(.*\)"$/\1/p' "$DD")"

# Every embedded JavaScript block must compile.
n=0
awk -v dir="$WORK" '
  /<<.JS.( |$)/ { inside = 1; n++; file = dir "/block" n ".js"; next }
  inside && /^JS$/ { inside = 0; close(file); next }
  inside { print > file }
' "$DD"
for f in "$WORK"/block*.js; do
  n=$((n + 1))
  check "JavaScript block $(basename "$f" .js) compiles" osacompile -l JavaScript -o "$WORK/$(basename "$f" .js).scpt" "$f"
done
(( n >= 5 )) && ok "found $n JavaScript blocks" || bad "expected at least 5 JavaScript blocks, found $n"

if [[ -z "$SRC" ]]; then
  echo
  echo "No Electron app given; skipping the profile tests."
else
  echo
  echo "Profile tests with $(basename "$SRC")"
  APPS="$WORK/apps"
  mkdir -p "$APPS"
  name="$(basename "$SRC" .app)"

  # launcher mode
  check "new (launcher)" /bin/bash "$DD" new --app "$SRC" --name "Ci one" --install-dir "$APPS" --data-dir "$WORK/data-one" --yes
  A="$APPS/$name Ci one.app"
  check "launcher app exists" test -x "$A/Contents/MacOS/doppeldock-launch"
  check "launcher signature is valid" codesign --verify --deep --strict "$A"
  check "launcher has a drawn icon" test -s "$A/Contents/Resources/doppeldock.icns"
  equals "launcher mode recorded" "$(plist "$A" DoppelDockMode)" launcher
  check "data folder marked" grep -q "local.doppeldock" "$WORK/data-one/.doppeldock-profile"
  check "launcher opens the original app" grep -q -- '--args --user-data-dir' "$A/Contents/MacOS/doppeldock-launch"

  # copy mode, with style and appearance
  check "new (copy, badge only, dark)" /bin/bash "$DD" new --app "$SRC" --name "Ci two" --mode copy --style badge \
    --appearance dark --color purple --install-dir "$APPS" --data-dir "$WORK/data-two" --yes
  B="$APPS/$name Ci two.app"
  exe="$(plist "$B" DoppelDockSourceExec)"
  check "copy signature is valid" codesign --verify --deep --strict "$B"
  check "copy keeps the hardened runtime" sh -c "codesign -dv '$B/Contents/MacOS/$exe' 2>&1 | grep -q runtime"
  check "copy can load the maker's frameworks" sh -c "codesign -d --entitlements - --xml '$B/Contents/MacOS/$exe' 2>/dev/null | grep -q disable-library-validation"
  check "copy has no keychain access groups" sh -c "! codesign -d --entitlements - --xml '$B/Contents/MacOS/$exe' 2>/dev/null | grep -q keychain-access-groups"
  check "copy hands links to the original" sh -c "! $PB -c 'Print :CFBundleURLTypes' '$B/Contents/Info.plist'"
  equals "copy style recorded" "$(plist "$B" DoppelDockStyle)" badge
  check "copy starts in dark mode" grep -q '^EXTRA_ARG=--force-dark-mode$' "$B/Contents/MacOS/doppeldock-launch"

  # change and rebuild keep the profile
  check "change copy to launcher, light" /bin/bash "$DD" change "$B" --mode launcher --appearance light
  equals "changed mode" "$(plist "$B" DoppelDockMode)" launcher
  equals "changed appearance" "$(plist "$B" DoppelDockAppearance)" light
  equals "style kept on change" "$(plist "$B" DoppelDockStyle)" badge
  equals "data folder kept on change" "$(plist "$B" DoppelDockDataDir)" "$WORK/data-two"
  check "rebuild" /bin/bash "$DD" rebuild "$B"
  equals "appearance kept on rebuild" "$(plist "$B" DoppelDockAppearance)" light

  # things it must refuse
  refuses "refuses an existing profile name" /bin/bash "$DD" new --app "$SRC" --name "Ci one" --install-dir "$APPS" --data-dir "$WORK/data-x" --yes
  refuses "refuses a name with ../" /bin/bash "$DD" new --app "$SRC" --name "x/../../y" --install-dir "$APPS" --yes
  refuses "refuses an unknown appearance" /bin/bash "$DD" new --app "$SRC" --name "Ci three" --appearance blue --install-dir "$APPS" --yes
  mkdir -p "$WORK/foreign" && echo keep > "$WORK/foreign/file"
  refuses "refuses someone else's data folder" /bin/bash "$DD" new --app "$SRC" --name "Ci four" --install-dir "$APPS" --data-dir "$WORK/foreign" --yes
  check "foreign data untouched" grep -q keep "$WORK/foreign/file"
  refuses "refuses to remove an app it did not make" /bin/bash "$DD" remove "$SRC"
  check "source app untouched" codesign --verify --deep --strict "$SRC"

  # install the DoppelDock app
  check "install the DoppelDock app" /bin/bash "$DD" install --dir "$APPS"
  check "DoppelDock app signature is valid" codesign --verify --deep --strict "$APPS/DoppelDock.app"
  check "DoppelDock app bundles this script" cmp -s "$DD" "$APPS/DoppelDock.app/Contents/Resources/doppeldock"

  # remove (to the Trash)
  check "remove launcher with its data" /bin/bash "$DD" remove "$A" --delete-data
  check "launcher app gone" test ! -e "$A"
  check "launcher data gone" test ! -e "$WORK/data-one"
  check "remove second profile, keep data" /bin/bash "$DD" remove "$B"
  check "kept data still there" test -f "$WORK/data-two/.doppeldock-profile"
fi

echo
echo "$pass passed, $fail failed"
(( fail == 0 ))
