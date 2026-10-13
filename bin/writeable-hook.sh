# Interactive commands use the same writable gems as the standalone launchers.
export LICHNIX_DATA_HOME="${LICHNIX_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/lichnix}"
export LICHNIX_WRITEABLE_SRC_HOME="${LICHNIX_WRITEABLE_SRC_HOME:-$LICHNIX_DATA_HOME/writeable/lich-5}"
export LICHNIX_GEM_HOME="$(@launcher@ -e 'print Gem.dir')"
export GEM_HOME="$LICHNIX_GEM_HOME"
export GEM_PATH="$GEM_HOME:@defaultGems@"
unset BUNDLE_PATH BUNDLE_FROZEN BUNDLE_DEPLOYMENT BUNDLE_WITH
export BUNDLE_GEMFILE="$LICHNIX_WRITEABLE_SRC_HOME/Gemfile"
export BUNDLE_IGNORE_CONFIG=1
export BUNDLE_VERSION=system
export RUBYOPT="-r@preload@${RUBYOPT:+ $RUBYOPT}"

lichh() { lich --no-gtk "$@"; }
