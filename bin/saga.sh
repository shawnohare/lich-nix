#!/usr/bin/env sh
set -eu

# Locate lich-nix relative to this script.
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

SAGA_APP="/Applications/Saga.app"

# Read the executable name from the macOS app bundle.
SAGA_EXECUTABLE=$(
  /usr/libexec/PlistBuddy \
    -c "Print CFBundleExecutable" \
    "${SAGA_APP}/Contents/Info.plist"
)

# Launch Saga inside the Nix development environment.
exec nix develop "${PROJECT_ROOT}" --command \
  "${SAGA_APP}/Contents/MacOS/${SAGA_EXECUTABLE}" "$@"
