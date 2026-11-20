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
# Interpreter for running the script under test. Default: macOS's /bin/bash 3.2.
# Coverage runs set TEST_BASH to a newer bash so kcov can trace it.
RUN="${TEST_BASH:-/bin/bash}"
SRC="${1:-}"
PB=/usr/libexec/PlistBuddy
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() {
  pass=$((pass + 1))
  printf '  ok    %s\n' "$1"
}
bad() {
  fail=$((fail + 1))
  printf '  FAIL  %s\n' "$1"
}
check() { # description, command...
  local d="$1"
  shift
  if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi
}
refuses() { # description, command... (must exit non-zero)
  local d="$1"
  shift
  if "$@" >/dev/null 2>&1; then bad "$d (was accepted)"; else ok "$d"; fi
}
plist() { $PB -c "Print :$2" "$1/Contents/Info.plist" 2>/dev/null; }
has_runtime() { [[ "$(codesign -dv "$1" 2>&1)" == *runtime* ]]; }
equals() { # description, actual, expected
  if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (got '$2', expected '$3')"; fi
}
fails_with() { # description, expected error text, command... (must fail with that text)
  local d="$1" msg="$2" out
  shift 2
  if out="$("$@" 2>&1)"; then
    bad "$d (was accepted)"
  elif [[ "$out" == *"$msg"* ]]; then
    ok "$d"
  else
    bad "$d (said: ${out##*$'\n'})"
  fi
}
# The menu and listings look in DOPPELDOCK_APPS_DIR (the test folder) too.
menu_run() { printf '%b' "$1" | DOPPELDOCK_APPS_DIR="${APPS:-}" "$RUN" "$DD" >/dev/null 2>&1; }
in_list() { [[ "$(DOPPELDOCK_APPS_DIR="$APPS" "$RUN" "$DD" list)" == *"$1"* ]]; }
in_profiles() { [[ "$(DOPPELDOCK_APPS_DIR="$APPS" "$RUN" "$DD" profiles)" == *"$1"* ]]; }
copy_cancelled() { printf 'n\n' | "$RUN" "$DD" new --app "$SRC" --name "Ci five" --mode copy --install-dir "$APPS"; }

echo "Static checks"
check "syntax under macOS's /bin/bash" /bin/bash -n "$DD"
if command -v shellcheck >/dev/null; then
  check "shellcheck (warnings and errors)" shellcheck -s bash -S warning "$DD" "$0"
else
  echo "  skip  shellcheck (not installed)"
fi
# Same shfmt as CI (shfmt-py 4.2.0); other versions may format slightly differently.
if [[ "$(shfmt --version 2>/dev/null)" == "v3.14.1" ]]; then
  check "shfmt (code style)" shfmt -d "$DD" "$0" "$ROOT/tests/coverage.sh" "$ROOT/tools/make-dmg.sh"
else
  echo "  skip  shfmt (needs v3.14.1, as in CI: uvx --from shfmt-py==4.2.0 shfmt)"
fi
check "help" "$RUN" "$DD" help
check "list" "$RUN" "$DD" list
check "menu opens, lists and quits" menu_run '2\nq\n'
refuses "refuses an unknown command" "$RUN" "$DD" frobnicate
refuses "refuses new without an app" "$RUN" "$DD" new --name x
refuses "refuses an option without a value" "$RUN" "$DD" new --app
refuses "refuses rebuild of a non-DoppelDock app" "$RUN" "$DD" rebuild /System/Applications/Calculator.app
equals "version string" "$("$RUN" "$DD" --version)" "DoppelDock $(sed -n 's/^VERSION="\(.*\)"$/\1/p' "$DD")"

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
((n >= 5)) && ok "found $n JavaScript blocks" || bad "expected at least 5 JavaScript blocks, found $n"

# The Mac app's own JavaScript, run with tests/gui_checks.js (nothing is shown or launched).
gui="$(grep -l 'function insertApp(' "$WORK"/block*.js | head -n 1)"
if [[ -f "$gui" ]]; then
  cat "$gui" "$ROOT/tests/gui_checks.js" >"$WORK/gui_checks.js"
  # Results go to stdout; system log noise on stderr is ignored unless osascript fails.
  if osascript -l JavaScript "$WORK/gui_checks.js" >"$WORK/gui_checks.out" 2>"$WORK/gui_checks.err"; then
    g=0
    while IFS= read -r line; do
      case "$line" in
        ok\ *) ok "${line#ok }" ;;
        FAIL\ *) bad "${line#FAIL }" ;;
        *) continue ;;
      esac
      g=$((g + 1))
    done <"$WORK/gui_checks.out"
    ((g == 6)) || bad "Mac app checks: expected 6 results, got $g"
  else
    bad "Mac app checks did not run: $(tail -n 1 "$WORK/gui_checks.err")"
  fi
else
  bad "Mac app code not found for its checks"
fi

# The website's structured data and llms.txt, run with tests/site_checks.js.
if osascript -l JavaScript "$ROOT/tests/site_checks.js" "$ROOT" >"$WORK/site_checks.out" 2>"$WORK/site_checks.err"; then
  s=0
  while IFS= read -r line; do
    case "$line" in
      ok\ *) ok "${line#ok }" ;;
      FAIL\ *) bad "${line#FAIL }" ;;
      *) continue ;;
    esac
    s=$((s + 1))
  done <"$WORK/site_checks.out"
  ((s == 4)) || bad "website checks: expected 4 results, got $s"
else
  bad "website checks did not run: $(tail -n 1 "$WORK/site_checks.err")"
fi

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
  check "new (launcher)" "$RUN" "$DD" new --app "$SRC" --name "Ci one" --install-dir "$APPS" --data-dir "$WORK/data-one" --yes
  A="$APPS/$name Ci one.app"
  check "launcher app exists" test -x "$A/Contents/MacOS/doppeldock-launch"
  check "launcher signature is valid" codesign --verify --deep --strict "$A"
  check "launcher has a drawn icon" test -s "$A/Contents/Resources/doppeldock.icns"
  equals "launcher mode recorded" "$(plist "$A" DoppelDockMode)" launcher
  check "data folder marked" grep -q "local.doppeldock" "$WORK/data-one/.doppeldock-profile"
  check "launcher opens the original app" grep -q -- '--args --user-data-dir' "$A/Contents/MacOS/doppeldock-launch"

  # copy mode, with style and appearance
  check "new (copy, badge only, dark)" "$RUN" "$DD" new --app "$SRC" --name "Ci two" --mode copy --style badge \
    --appearance dark --color purple --install-dir "$APPS" --data-dir "$WORK/data-two" --yes
  B="$APPS/$name Ci two.app"
  exe="$(plist "$B" DoppelDockSourceExec)"
  check "copy signature is valid" codesign --verify --deep --strict "$B"
  check "copy keeps the hardened runtime" has_runtime "$B/Contents/MacOS/$exe"
  check "copy can load the maker's frameworks" sh -c "codesign -d --entitlements - --xml '$B/Contents/MacOS/$exe' 2>/dev/null | grep -q disable-library-validation"
  check "copy has no keychain access groups" sh -c "! codesign -d --entitlements - --xml '$B/Contents/MacOS/$exe' 2>/dev/null | grep -q keychain-access-groups"
  check "copy hands links to the original" sh -c "! $PB -c 'Print :CFBundleURLTypes' '$B/Contents/Info.plist'"
  equals "copy style recorded" "$(plist "$B" DoppelDockStyle)" badge
  check "copy starts in dark mode" grep -q '^EXTRA_ARG=--force-dark-mode$' "$B/Contents/MacOS/doppeldock-launch"

  # change and rebuild keep the profile
  check "change copy to launcher, light" "$RUN" "$DD" change "$B" --mode launcher --appearance light
  equals "changed mode" "$(plist "$B" DoppelDockMode)" launcher
  equals "changed appearance" "$(plist "$B" DoppelDockAppearance)" light
  equals "style kept on change" "$(plist "$B" DoppelDockStyle)" badge
  equals "data folder kept on change" "$(plist "$B" DoppelDockDataDir)" "$WORK/data-two"
  check "rebuild" "$RUN" "$DD" rebuild "$B"
  equals "appearance kept on rebuild" "$(plist "$B" DoppelDockAppearance)" light

  # things it must refuse
  refuses "refuses an existing profile name" "$RUN" "$DD" new --app "$SRC" --name "Ci one" --install-dir "$APPS" --data-dir "$WORK/data-x" --yes
  refuses "refuses a name with ../" "$RUN" "$DD" new --app "$SRC" --name "x/../../y" --install-dir "$APPS" --yes
  refuses "refuses an unknown appearance" "$RUN" "$DD" new --app "$SRC" --name "Ci three" --appearance blue --install-dir "$APPS" --yes
  mkdir -p "$WORK/foreign" && echo keep >"$WORK/foreign/file"
  refuses "refuses someone else's data folder" "$RUN" "$DD" new --app "$SRC" --name "Ci four" --install-dir "$APPS" --data-dir "$WORK/foreign" --yes
  check "foreign data untouched" grep -q keep "$WORK/foreign/file"
  refuses "refuses to remove an app it did not make" "$RUN" "$DD" remove "$SRC"
  check "source app untouched" codesign --verify --deep --strict "$SRC"

  # option parsing and colours: each run stops at the bad mode, after the options are checked
  for c in green blue purple pink orange teal red gray grey '#12AB9f'; do
    fails_with "colour $c is accepted" "mode must be" "$RUN" "$DD" new --app "$SRC" --name "Ci c" --color "$c" --mode bogus --install-dir "$APPS" --yes
  done
  fails_with "all new options are parsed" "mode must be" "$RUN" "$DD" new --app "$SRC" --name "Ci o" --badge AB --style tint \
    --appearance light --data-dir "$WORK/data-o" --adopt-data-dir --install-dir "$APPS" --mode bogus --yes
  fails_with "refuses an unknown colour" "unknown colour" "$RUN" "$DD" new --app "$SRC" --name "Ci c" --color mauve --install-dir "$APPS" --yes
  fails_with "refuses a short colour code" "unknown colour" "$RUN" "$DD" new --app "$SRC" --name "Ci c" --color '#12' --install-dir "$APPS" --yes
  fails_with "refuses an unknown option" "unknown option" "$RUN" "$DD" new --bogus
  fails_with "own icon asks before copying" "cancelled" copy_cancelled
  fails_with "change needs an app" "usage" "$RUN" "$DD" change
  fails_with "change refuses an unknown option" "unknown option" "$RUN" "$DD" change "$B" --bogus
  fails_with "change refuses an unknown colour" "unknown colour" "$RUN" "$DD" change "$B" --color mauve
  fails_with "change refuses a non-DoppelDock app" "not made by DoppelDock" "$RUN" "$DD" change "$SRC"
  fails_with "rebuild refuses an unknown option" "unknown option" "$RUN" "$DD" rebuild --bogus
  fails_with "rebuild takes one app" "one app path" "$RUN" "$DD" rebuild "$B" "$B"
  fails_with "remove refuses an unknown option" "unknown option" "$RUN" "$DD" remove --bogus
  fails_with "remove takes one app" "one app path" "$RUN" "$DD" remove "$B" "$B"
  fails_with "install refuses an unknown option" "unknown option" "$RUN" "$DD" install --bogus

  # change colour, badge and style
  check "change colour, badge and style" "$RUN" "$DD" change "$B" --color red --badge Q --style tint
  equals "colour changed" "$(plist "$B" DoppelDockColor)" "#E03131"
  equals "badge changed" "$(plist "$B" DoppelDockBadge)" Q
  equals "style changed" "$(plist "$B" DoppelDockStyle)" tint

  # listing (DOPPELDOCK_APPS_DIR adds the test folder to where DoppelDock looks)
  check "list shows the profiles" in_list "Ci one"
  check "profiles lists the test profiles" in_profiles "$name Ci two.app"

  # installed with Homebrew: copies must call the stable "opt" path, not the versioned Cellar one
  BREW="$WORK/brew"
  mkdir -p "$BREW/Cellar/doppeldock/9.9.9/bin" "$BREW/opt/doppeldock/bin"
  cp "$DD" "$BREW/Cellar/doppeldock/9.9.9/bin/doppeldock"
  ln -s "../../../Cellar/doppeldock/9.9.9/bin/doppeldock" "$BREW/opt/doppeldock/bin/doppeldock"
  check "new (copy) from a Homebrew install" "$RUN" "$BREW/opt/doppeldock/bin/doppeldock" new --app "$SRC" --name "Ci brew" \
    --mode copy --install-dir "$APPS" --data-dir "$WORK/data-brew" --yes
  check "copy from Homebrew calls the opt path" grep -q "^DOPPELDOCK=$(cd "$BREW" && pwd -P)/opt/doppeldock/bin/doppeldock\$" "$APPS/$name Ci brew.app/Contents/MacOS/doppeldock-launch"
  check "remove the Homebrew test profile" "$RUN" "$DD" remove "$APPS/$name Ci brew.app" --delete-data

  # install the DoppelDock app
  check "install the DoppelDock app" "$RUN" "$DD" install --dir "$APPS"
  check "DoppelDock app signature is valid" codesign --verify --deep --strict "$APPS/DoppelDock.app"
  check "DoppelDock app bundles this script" cmp -s "$DD" "$APPS/DoppelDock.app/Contents/Resources/doppeldock"

  # a copy made from a temporary download calls the installed DoppelDock app to rebuild
  TMPS="$(mktemp -d)"
  cp "$DD" "$TMPS/doppeldock"
  check "new (copy) from a temporary download" env DOPPELDOCK_APPS_DIR="$APPS" "$RUN" "$TMPS/doppeldock" new --app "$SRC" \
    --name "Ci temp" --mode copy --install-dir "$APPS" --data-dir "$WORK/data-temp" --yes
  check "copy from a download calls the installed app" grep -qF "DOPPELDOCK=$APPS/DoppelDock.app/Contents/Resources/doppeldock" \
    "$APPS/$name Ci temp.app/Contents/MacOS/doppeldock-launch"
  check "remove the download test profile" "$RUN" "$DD" remove "$APPS/$name Ci temp.app" --delete-data
  rm -rf "$TMPS"

  # the Terminal menu: new, update and remove a profile
  check "menu: new profile" menu_run "1\n$SRC\nMenu one\n2\nn\nq\n"
  check "menu: profile made" test -d "$APPS/$name Menu one.app"
  check "menu: update a profile" menu_run "3\n$APPS/$name Menu one.app\nq\n"
  check "menu: remove a profile and its data" menu_run "4\n$APPS/$name Menu one.app\ny\ny\nq\n"
  check "menu: profile removed" test ! -e "$APPS/$name Menu one.app"
  check "menu: back out of new profile" menu_run "1\nq\nq\n"
  check "menu: unknown choice" menu_run "9\nq\n"

  # remove (to the Trash)
  check "remove launcher with its data" "$RUN" "$DD" remove "$A" --delete-data
  check "launcher app gone" test ! -e "$A"
  check "launcher data gone" test ! -e "$WORK/data-one"
  check "remove second profile, keep data" "$RUN" "$DD" remove "$B"
  check "kept data still there" test -f "$WORK/data-two/.doppeldock-profile"
fi

echo
echo "$pass passed, $fail failed"
((fail == 0))
