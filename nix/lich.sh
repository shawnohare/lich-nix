set -eu
export LICHNIX_DATA_HOME="${LICHNIX_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/lichnix}"
if [ "@mode@" = writeable ]; then
  checkout="${LICHNIX_WRITEABLE_SRC_HOME:-$LICHNIX_DATA_HOME/src/lich-5}"
else
  checkout="$LICHNIX_DATA_HOME/runtime"
  @prepare@
fi
if [ ! -f "$checkout/lich.rbw" ]; then
  echo "lich: missing $checkout/lich.rbw; prepare the @mode@ runtime first." >&2
  exit 1
fi
cd "$checkout"
if [ "@mode@" = writeable ]; then export LICHNIX_WRITEABLE_SRC_HOME="$PWD"; fi
exec @launcher@/bin/@rubyProgram@ "$PWD/lich.rbw" "$@"
