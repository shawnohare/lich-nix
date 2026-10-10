# Shell template: Nix replaces @ruby@ with the pinned Ruby executable.
set -eu

# Desktop-launched Saga does not inherit shell configuration.
config="${XDG_CONFIG_HOME:-$HOME/.config}/lich-nix/runtime.sh"
if [ -f "$config" ]; then
  . "$config"
fi

export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export LICH_DATA_HOME="${LICH_DATA_HOME:-$XDG_DATA_HOME/lich-5}"
export LICH_SRC_HOME="${LICH_SRC_HOME:-$LICH_DATA_HOME}"
export BUNDLE_GEMFILE="${BUNDLE_GEMFILE:-$LICH_SRC_HOME/Gemfile}"
export BUNDLE_PATH="${BUNDLE_PATH:-$XDG_DATA_HOME/lich-nix/bundle}"

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
if [ ! -f "$BUNDLE_GEMFILE" ]; then
  echo "saga-ruby: Gemfile not found: $BUNDLE_GEMFILE" >&2
  echo "Install Lich and its gems, or set LICH_SRC_HOME in $config." >&2
  exit 1
fi

cd "$LICH_SRC_HOME"
exec @ruby@ -rbundler/setup "$@"
