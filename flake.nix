
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
        ];

        shellHook = ''
          export BUNDLE_PATH="$PWD/upstream/.bundle"
          export BUNDLE_WITHOUT="development:vscode"

          echo "Ruby: $(ruby --version)"
          echo "Bundler: $(bundle --version)"
        '';
      };
    };
}

