# Ruby-compatible entry point: do not change cwd, script arguments, or exit status.
set -eu
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export LICHNIX_DATA_HOME="${LICHNIX_DATA_HOME:-$XDG_DATA_HOME/lichnix}"
export LICHNIX_WRITEABLE_SRC_HOME="${LICHNIX_WRITEABLE_SRC_HOME:-$LICHNIX_DATA_HOME/src/lich-5}"
case "$LICHNIX_WRITEABLE_SRC_HOME" in /*) ;; *) export LICHNIX_WRITEABLE_SRC_HOME="$PWD/$LICHNIX_WRITEABLE_SRC_HOME" ;; esac
export LICHNIX_GEM_HOME="${LICHNIX_GEM_HOME:-$LICHNIX_WRITEABLE_SRC_HOME/.bundle/gems-@toolchainId@}"
case "$LICHNIX_GEM_HOME" in /*) ;; *) export LICHNIX_GEM_HOME="$PWD/$LICHNIX_GEM_HOME" ;; esac
export GEM_HOME="$LICHNIX_GEM_HOME"
export GEM_PATH="$GEM_HOME:@defaultGems@"

# No global Bundler activation: scripts may install and load additional gems.
# Local bundle settings must not redirect installation to an older environment.
unset BUNDLE_PATH BUNDLE_FROZEN BUNDLE_DEPLOYMENT BUNDLE_WITH
export BUNDLE_GEMFILE="$LICHNIX_WRITEABLE_SRC_HOME/Gemfile"
export BUNDLE_IGNORE_CONFIG=1
export BUNDLE_VERSION=system
case "${RUBYOPT:-}" in
  *bundler/setup*) echo "writeable Ruby: remove bundler/setup from RUBYOPT before using writeable mode." >&2; exit 1 ;;
esac
case " ${RUBYOPT:-} " in
  *" -r@preload@ "*) ;;
  *) export RUBYOPT="-r@preload@${RUBYOPT:+ $RUBYOPT}" ;;
esac
source @toolchain@/env.sh
exec @ruby@ "$@"
