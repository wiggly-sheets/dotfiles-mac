#!/usr/bin/env bash
set -u

# Resolve PACKAGE to the script's directory (absolute)
PACKAGE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"

# Helper to exit whether the script is sourced or run
_fail() {
  echo "$1" >&2
  # if sourced, 'return' is appropriate; otherwise exit
  (return 1 2>/dev/null) || exit 1
}

if [ "$(uname -p)" != "arm" ]; then
  _fail "Only arm is supported"
fi

if ! nvram boot-args | grep -q -E '(-arm64e_preview_abi|amfi_get_out_of_my_way=1)'; then
  _fail "SIP was not disabled properly (required boot-args not present)"
fi


xattr -c "$PACKAGE/dylinject"
xattr -c "$PACKAGE/spaces-renamer.dylib"
if [ ! -f "$PACKAGE/dylinject" ]; then
  _fail "dylinject not found or not executable at: $PACKAGE/dylinject"
fi

if [ ! -f "$PACKAGE/spaces-renamer.dylib" ]; then
  _fail "dylib not found at: $PACKAGE/spaces-renamer.dylib"
fi

sudo "$PACKAGE/dylinject" com.apple.dock "$PACKAGE/spaces-renamer.dylib"
