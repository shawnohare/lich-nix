# Shell template: Nix replaces @ruby@ with the pinned Ruby executable.
set -eu

export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export LICHNIX_DATA_HOME="${LICHNIX_DATA_HOME:-$XDG_DATA_HOME/lichnix}"
checkout="$LICHNIX_DATA_HOME/runtime"
# Always use the packaged dependency set, including for Finder launches.
# Ignore stale bundle configuration in the runtime home or user's home.
unset BUNDLE_PATH BUNDLE_WITH BUNDLE_WITHOUT
export BUNDLE_IGNORE_CONFIG=1
export BUNDLE_FROZEN=1
export BUNDLE_WITHOUT="development:vscode"
export BUNDLE_GEMFILE="@gemfile@"
export GEM_HOME="@gemhome@"
export GEM_PATH="$GEM_HOME"

# Let frontends probe Ruby without preparing application state.
if [ "$#" -eq 1 ]; then
  case "$1" in
    --version|-v) exec @ruby@ "$@" ;;
  esac
fi
if [ "$#" -eq 0 ]; then
  echo "Usage: ruby-lich [Ruby options] PATH_TO_LICH_RBW [arguments...]" >&2
  exit 2
fi
@prepare@

cd "$checkout"
exec @ruby@ -rbundler/setup "$@"
