
{
  description = "Lich 5 nix environment";

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
      lichBundix = pkgs.callPackage ./nix/bundix.nix { };

      lichGems = pkgs.callPackage ./nix/lich-gems.nix { };
      developmentGems = pkgs.callPackage ./nix/lich-gems.nix {
        groups = [ "default" "gtk" "profanity" "development" "vscode" ];
      };

      fontsConf = pkgs.makeFontsConf {
        fontDirectories = [
          pkgs.dejavu_fonts
        ];
      };

      sagaRuby = pkgs.callPackage ./nix/saga-ruby.nix {
        inherit fontsConf lichGems;
      };

    in
    {
      packages.${system} = {
        lich-gems = lichGems;
        lich-development-gems = developmentGems;
        bundix = lichBundix;
        saga-ruby = sagaRuby;
        default = sagaRuby;
      };

      apps.${system}.saga-ruby = {
        type = "app";
        program = "${sagaRuby}/bin/saga-ruby";
      };

      # Dependency maintenance must work even when the packaged gems cannot
      # build yet, and must not inherit the frozen runtime configuration.
      devShells.${system} = {
        gem-tools = pkgs.mkShell {
          packages = [ pkgs.ruby_4_0 lichBundix ];
          shellHook = ''
            unset BUNDLE_GEMFILE BUNDLE_PATH BUNDLE_WITH BUNDLE_WITHOUT GEM_HOME GEM_PATH
            export BUNDLE_IGNORE_CONFIG=1
            export BUNDLE_FROZEN=0
            export BUNDLE_FORCE_RUBY_PLATFORM=1
          '';
        };

        default = pkgs.mkShell {

          packages = with pkgs; [
            # Ruby and build tools
            developmentGems.wrappedRuby
            developmentGems
            pkg-config
            lichBundix

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
            unset BUNDLE_PATH BUNDLE_WITH BUNDLE_WITHOUT
            export BUNDLE_IGNORE_CONFIG=1
            export BUNDLE_FROZEN=1
            export BUNDLE_GEMFILE="${developmentGems.confFiles}/Gemfile"
            export GEM_HOME="${developmentGems}/${pkgs.ruby_4_0.gemPath}"
            export GEM_PATH="$GEM_HOME"
            export FONTCONFIG_FILE="${fontsConf}"
            export LICH_REV="${lich-src.rev}"
          '';
        };
      };

      checks.${system} = {
        maintenance-helpers = pkgs.runCommand "lich-maintenance-helpers-check" {
          nativeBuildInputs = [ pkgs.python3 pkgs.bash ];
          LICH_MAINTENANCE_BIN = "${./bin}";
        } ''
          python3 ${./tests/test_maintenance_scripts.py}
          touch "$out"
        '';
        upstream-gemfile = pkgs.runCommand "lich-upstream-gemfile" { } ''
          cmp ${lich-src}/Gemfile ${./nix/gems/Gemfile}
          touch "$out"
        '';
        launcher = pkgs.runCommand "lich-launcher-check" {
          nativeBuildInputs = [ pkgs.python3 ];
          SAGA_RUBY = "${sagaRuby}/bin/saga-ruby";
        } ''
          python3 ${./tests/test_saga_ruby.py}
          touch "$out"
        '';
      };
    };
}

