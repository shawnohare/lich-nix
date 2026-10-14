# Offline setup: prepare a writable home from the application in the Nix closure.
set -euo pipefail
exec @ruby@ "@source@/packaged-state.rb" "@source@"
