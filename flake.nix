
{
  description = "Lich 5 development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          ruby_4_0
          pkg-config
          bundix

          # Native dependencies
          gtk3
          gobject-introspection
          glib
          cairo
          pango
          gdk-pixbuf
          sqlite
          openssl
          libffi
          libyaml
          zlib

          # Headless dependencies
          ncurses
        ];

        shellHook = ''
          # export BUNDLE_PATH="$PWD/upstream/.bundle"
          # export BUNDLE_WITHOUT="development:vscode"
          # export LICH_ROOT="$PWD/upstream/lich-5"
          # export BUNDLE_PATH="''${XDG_DATA_HOME:-$HOME/.local/share}/lich5/bundle"
          # Small wrapper to launch lich.
          # lich() {
          #   (
          #     cd "$LICH_ROOT" || return 1
          #     bundle exec ruby lich.rbw "$@"
          #   )
          # }
          #
          # # Headless lich wrapper
          # lichh() {
          #   (
          #     cd "$LICH_ROOT" || return 1
          #     bundle exec ruby lich.rbw --no-gtk "$@"
          #   )
          # }
          #
          # echo "Ruby: $(ruby --version)"
          # echo "Bundler: $(bundle --version)"
          source ./bin/hook.sh
        '';
      };
    };
}

