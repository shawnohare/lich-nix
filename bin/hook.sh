# Paths for the writable Lich checkout and application data.

export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
# For some reason lich doesn't expose a single config option for where it puts
# user data. You have to pass in half a dozen args. Until it does, we'll let it
# use its defaults.
export LICHNIX_DATA_HOME="${LICHNIX_DATA_HOME:-${XDG_DATA_HOME}/lichnix}"
lich_checkout="$LICHNIX_DATA_HOME/runtime"

# Small wrapper to launch lich.
lich() {
    cd "${lich_checkout}" || return 1
    bundle exec ruby "$LICHNIX_PACKAGED_ENTRY" "$@"
}

# Headless lich wrapper
lichh() {
    cd "${lich_checkout}" || return 1
    lich --no-gtk "$@"
}

echo "Ruby: $(ruby --version)"
echo "Bundler: $(bundle --version)"
echo "Packaged runtime home: ${lich_checkout}"
echo "LICHNIX_DATA_HOME: ${LICHNIX_DATA_HOME}"
