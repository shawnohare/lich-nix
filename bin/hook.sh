# nix develop shell hook for POC (no GTK)

# export BUNDLE_PATH="$PWD/upstream/.bundle"
# export BUNDLE_WITHOUT="development:vscode"

export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
# For some reason lich doesn't expose a single config option for where it puts
# user data. You have to pass in half a dozen args. Until it does, we'll let it
# use its defaults.
export LICH_DATA_HOME="${LICH_DATA_HOME:-${XDG_DATA_HOME}/lich-5}"
export LICH_SRC_HOME="${LICH_SRC_HOME:-${LICH_DATA_HOME}}"

# export BUNDLE_WITHOUT=gtk
export BUNDLE_GEMFILE="${LICH_SRC_HOME}/Gemfile"
export BUNDLE_PATH="${XDG_DATA_HOME}/lich-nix/bundle"

# Small wrapper to launch lich.
lich() {
    (
      cd "${LICH_SRC_HOME}" || return 1
      bundle exec ruby lich.rbw "$@"
    )
}

# Headless lich wrapper
lichh() {
    (
      cd "${LICH_SRC_HOME}" || return 1
      bundle exec ruby lich.rbw --no-gtk "$@"
    )
}

echo "Ruby: $(ruby --version)"
echo "Bundler: $(bundle --version)"
echo "BUNDLE_GEMFILE: ${BUNDLE_GEMFILE}"
echo "BUNDLE_PATH: ${BUNDLE_PATH}"
echo "LICH_SRC_HOME (lich.rbw): ${LICH_SRC_HOME}"
echo "LICH_DATA_HOME (scripts, logs, etc.): ${LICH_DATA_HOME}"
