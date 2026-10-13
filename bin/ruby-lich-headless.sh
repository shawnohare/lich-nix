#!/usr/bin/env sh
# Small wrapper that exposes a "ruby executable" where ruby is using the
# nix development environment. Intended to be used with front-ends like Saga.
# Assumes that `nix develop` has been invoked. In particular, that saga has
# been launched from the lichnix development shell.

set -eu


if [ "$#" -eq 0 ]; then
  echo "Usage: ruby-lich PATH_TO_LICH_RBW [arguments...]" >&2
  exit 2
fi

lich_checkout="${LICHNIX_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/lichnix}/packaged/lich-5"
cd "$lich_checkout"

# TODO: Could add all the data dir args to pass to lich here, but that seems
# like a headache.
export BUNDLE_WITHOUT=gtk
exec ruby -rbundler/setup "$@" --no-gtk
