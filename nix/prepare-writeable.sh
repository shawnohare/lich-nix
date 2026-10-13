# Prepare a writable Lich checkout and gems. New clones start at the flake pin;
# existing Git checkouts keep their revision and local changes.
set -euo pipefail
if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  echo "Usage: prepare-writeable [CHECKOUT_PATH]"
  echo "Clone pinned Lich if needed, install gems, and write .bundle/bin launchers."
  exit 0
fi
if [[ $# -gt 1 ]]; then echo "Usage: prepare-writeable [CHECKOUT_PATH]" >&2; exit 2; fi
export LICHNIX_DATA_HOME="${LICHNIX_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/lichnix}"
checkout="${1:-${LICHNIX_WRITEABLE_SRC_HOME:-$LICHNIX_DATA_HOME/writeable/lich-5}}"
# Git refuses a nonempty destination rather than overwriting its contents.
# Accept .git files too, so an existing worktree is treated as a checkout.
if [[ ! -e $checkout/.git ]]; then
  mkdir -p -- "$(dirname -- "$checkout")"
  git clone -- https://github.com/elanthia-online/lich-5.git "$checkout"
  git -C "$checkout" switch --detach @lichRev@
fi
if [[ ! -f $checkout/lich.rbw || ! -f $checkout/Gemfile ]]; then
  echo "prepare-writeable: expected lich.rbw and Gemfile in $checkout." >&2
  exit 1
fi
checkout=$(CDPATH='' cd -- "$checkout" && pwd -P)
export LICHNIX_WRITEABLE_SRC_HOME="$checkout"
gemhome=$(@runtime@/bin/ruby-lich -e 'print Gem.dir')
mkdir -p -- "$gemhome" "$checkout/.bundle/bin"

# Retain the complete native runtime/build environment before compiling gems.
# This also keeps its preload alive in raw-Ruby child processes after GC.
nix-store --add-root "$gemhome/toolchain-root" --indirect --realise @runtime@ >/dev/null
cd "$checkout"
BUNDLE_PATH__SYSTEM=true BUNDLE_FORCE_RUBY_PLATFORM=1 \
  BUNDLE_WITHOUT="${BUNDLE_WITHOUT-development:vscode}" \
  @runtime@/bin/ruby-lich -S bundle install

# Check native dependencies without contacting the game or opening a window.
@runtime@/bin/ruby-lich -e 'require "sqlite3"; require "gtk3"; GObjectIntrospection::Repository.default.require("Gtk", "3.0"); raise "SQLite failed" unless SQLite3::Database.new(":memory:").get_first_value("select 42") == 42'

# Write settings into ordinary Bash wrappers so Finder launches do not depend
# on terminal exports. Shell quoting handles spaces and literal shell characters.
for program in ruby-lich lich; do
  candidate=$(mktemp "$checkout/.bundle/bin/.${program}.XXXXXXXX")
  {
    printf '#!@bash@\nset -eu\n'
    printf 'export LICHNIX_DATA_HOME=%q\n' "$LICHNIX_DATA_HOME"
    printf 'export LICHNIX_WRITEABLE_SRC_HOME=%q\n' "$checkout"
    printf 'export LICHNIX_GEM_HOME=%q\n' "$gemhome"
    printf 'exec %q "$@"\n' "@runtime@/bin/$program"
  } > "$candidate"
  chmod +x "$candidate"
  mv -f -- "$candidate" "$checkout/.bundle/bin/$program"
done
echo "Lich checkout: $checkout"
echo "Writable gems: $gemhome"
echo "Run Lich: $checkout/.bundle/bin/lich"
echo "Lich Ruby: $checkout/.bundle/bin/ruby-lich"
