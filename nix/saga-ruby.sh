# Shell template: Nix replaces @ruby@ with the pinned Ruby executable.
set -eu

export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export LICH_DATA_HOME="${LICH_DATA_HOME:-$XDG_DATA_HOME/lich-5}"
export LICH_SRC_HOME="${LICH_SRC_HOME:-$LICH_DATA_HOME}"
# Always use the packaged dependency set, including for Finder launches.
# Ignore stale bundle configuration in the checkout or user's home.
unset BUNDLE_PATH BUNDLE_WITH BUNDLE_WITHOUT
export BUNDLE_IGNORE_CONFIG=1
export BUNDLE_FROZEN=1
export BUNDLE_WITHOUT="development:vscode"
export BUNDLE_GEMFILE="@gemfile@"
export GEM_HOME="@gemhome@"
export GEM_PATH="$GEM_HOME"

# Let frontends probe Ruby without requiring an installed checkout.
if [ "$#" -eq 1 ]; then
  case "$1" in
    --version|-v) exec @ruby@ "$@" ;;
  esac
fi
if [ "$#" -eq 0 ]; then
  echo "Usage: saga-ruby [Ruby options] PATH_TO_LICH_RBW [arguments...]" >&2
  exit 2
fi
if [ ! -d "$LICH_SRC_HOME" ]; then
  echo "saga-ruby: Lich directory not found: $LICH_SRC_HOME" >&2
  echo "Install Lich, or set LICH_SRC_HOME in the launch environment." >&2
  exit 1
fi

cd "$LICH_SRC_HOME"
exec @ruby@ -rbundler/setup "$@"
