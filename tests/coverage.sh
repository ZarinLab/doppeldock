#!/bin/bash
# Statement coverage of the doppeldock script's shell code, measured with bashcov.
#
#   tests/coverage.sh /path/to/Electron-based.app [minimum-percent]
#
# Runs tests/smoke.sh with the script traced by bashcov (SimpleCov), then counts
# only shell statements: heredoc bodies (the Mac app's JavaScript, generated
# scripts and texts) are left out, because bashcov marks them covered whenever
# the heredoc is written. The JavaScript is compile-checked by smoke.sh, which
# also runs tests/gui_checks.js on the Mac app's code.
# Fails below the minimum (default 80). Tracing needs a bash newer than macOS's
# 3.2 (BASH_XTRACEFD):
#   brew install bash && bundle install
# The HTML report (which still includes heredoc lines) is left in coverage/.

set -euo pipefail

# On-disk letter case (macOS is case-insensitive), so bashcov sees one file, not two.
ROOT="$(/bin/realpath "$(dirname "$0")/..")"
SRC="${1:?usage: tests/coverage.sh /path/to/Electron-based.app [minimum-percent]}"
MIN="${2:-80}"
BASH5="${COVERAGE_BASH:-$(brew --prefix 2>/dev/null)/bin/bash}"
command -v bashcov >/dev/null || {
  echo "coverage: bashcov not found (bundle install)" >&2
  exit 1
}
[[ -x "$BASH5" ]] || {
  echo "coverage: needs a newer bash, e.g. brew install bash" >&2
  exit 1
}

cd "$ROOT"
rm -rf coverage
TEST_BASH="$BASH5" bashcov --root "$ROOT" --bash-path "$BASH5" -- tests/smoke.sh "$SRC"

pct="$(ruby "$ROOT/tests/coverage_lines.rb" "$ROOT/doppeldock" coverage/coverage.json)"
echo "Statement coverage of doppeldock: $pct% (minimum $MIN%)"
echo "Report: $ROOT/coverage/index.html"
ruby -e 'exit(ARGV[0].to_f >= ARGV[1].to_f ? 0 : 1)' "$pct" "$MIN"
