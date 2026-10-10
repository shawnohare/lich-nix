#!/usr/bin/env sh
# Small wrapper that exposes a "ruby executable" where ruby is using the
# nix development environment. Intended to be used with front-ends like Saga.
# Assumes that `nix develop` has been invoked. In particular, that saga has
# been launched from the lich-nix development shell.

set -eu


if [ "$#" -eq 0 ]; then
  echo "Usage: ruby-lich PATH_TO_LICH_RBW [arguments...]" >&2
  exit 2
fi

cd "${LICH_SRC_HOME}"

# TODO: Could add all the data dir args to pass to lich here, but that seems
# like a headache.
exec ruby -rbundler/setup "$@" \
    --home="${LICH_SRC_HOME}" \
    --script-dir="${LICH_SRC_HOME}/user/scripts" \
    --map-dir="${LICH_SRC_HOME}/user/maps" \
    --log-dir="${LICH_SRC_HOME}/user/logs" \
    --backup-dir="${LICH_SRC_HOME}/user/backup" \
    --data-dir="${LICH_SRC_HOME}/user/data-dir" \
    --active-session-dir="${LICH_SRC_HOME}/user/sessions"
