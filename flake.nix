
{
  description = "Lich 5 development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    lich-src = {
      url = "github:elanthia-online/lich-5?ref=v5.22.0";
      flake = false;
    };
  };

  outputs = { nixpkgs, lich-src, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};

      fontsConf = pkgs.makeFontsConf {
        fontDirectories = [
          pkgs.dejavu_fonts
        ];
      };

      sagaRuby = pkgs.callPackage ./nix/saga-ruby.nix {
        inherit fontsConf;
      };

      # macOS font libs.
      # fontsConf = pkgs.makeFontsConf {
      #   fontDirectories = [
      #     "/System/Library/Fonts"
      #     "/Library/Fonts"
      #   ];
      # };
    in
    {
      packages.${system} = {
        saga-ruby = sagaRuby;
        default = sagaRuby;
      };

      apps.${system}.saga-ruby = {
        type = "app";
        program = "${sagaRuby}/bin/saga-ruby";
      };

      devShells.${system}.default = pkgs.mkShell {

        packages = with pkgs; [
          # Ruby and build tools
          ruby_4_0
          pkg-config
          bundix

          # Core native dependencies
          libffi
          libyaml
          ncurses
          openssl
          sqlite
          zlib

          # GTK native libraries and bindings' build dependencies
          cairo
          gdk-pixbuf
          glib
          gobject-introspection
          gtk3
          pango

          # Additional transitive pkg-config dependencies
          expat
          libdatrie
          libepoxy
          libpthread-stubs
          libsysprof-capture
          libthai
          libxdmcp
          pcre2

          # GTK graphical runtime assets
          adwaita-icon-theme
          hicolor-icon-theme
          librsvg
          shared-mime-info
        ];

        shellHook = ''
          source ./bin/hook.sh
          export FONTCONFIG_FILE="${fontsConf}"
          export LICH_REV="${lich-src.rev}"
        '';
      };
    };
}

