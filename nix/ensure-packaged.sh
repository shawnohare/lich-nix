# First-launch setup only. Existing Git checkouts are never fetched or switched.
set -euo pipefail
export LICHNIX_DATA_HOME="${LICHNIX_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/lichnix}"
checkout="$LICHNIX_DATA_HOME/packaged/lich-5"
if [[ -e $checkout/.git ]]; then
  if [[ ! -f $checkout/lich.rbw || ! -f $checkout/Gemfile ]]; then
    echo "lichnix: expected lich.rbw and Gemfile in $checkout." >&2
    exit 1
  fi
  exit 0
fi
if [[ -e $checkout ]] && { [[ ! -d $checkout ]] || [[ -n $(ls -A "$checkout") ]]; }; then
  echo "lichnix: refusing to overwrite nonempty checkout destination: $checkout" >&2
  exit 1
fi

# Publish only a complete clone, so failed setup can be retried on the next run.
mkdir -p -- "$(dirname -- "$checkout")"
candidate=$(mktemp -d "$(dirname -- "$checkout")/.lich-5.XXXXXXXX")
trap 'rm -rf -- "$candidate"' EXIT
echo "lichnix: initializing $checkout at pinned commit @lichRev@" >&2
git clone -- https://github.com/elanthia-online/lich-5.git "$candidate"
git -C "$candidate" switch --detach @lichRev@
if [[ -d $checkout ]]; then rmdir -- "$checkout"; fi
mv -T -- "$candidate" "$checkout"
