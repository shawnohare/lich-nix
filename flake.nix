{
  description = "lichnix: Ruby and native dependencies for Lich 5";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    lich-src = {
      # GitHub release archives omit Gemfile.lock via upstream's export-ignore.
      url = "git+https://github.com/elanthia-online/lich-5?ref=refs/tags/v5.22.0&shallow=1";
      flake = false;
    };
  };

  outputs = {
    nixpkgs,
    lich-src,
    ...
  }: let
    system = "aarch64-darwin";
    pkgs = nixpkgs.legacyPackages.${system};
    toolchain = import ./nix/toolchain.nix {inherit pkgs;};
    lichBundix = pkgs.callPackage ./nix/bundix.nix {};

    lichGems = pkgs.callPackage ./nix/lich-gems.nix {inherit lich-src;};
    developmentGems = lichGems.override {excludedGroups = [];};

    fontsConf = pkgs.makeFontsConf {
      fontDirectories = [
        pkgs.dejavu_fonts
      ];
    };

    packagedSetup = pkgs.writeShellApplication {
      name = "ensure-packaged";
      runtimeInputs = [pkgs.git pkgs.coreutils];
      text =
        pkgs.lib.replaceStrings ["@lichRev@"]
        [lich-src.rev] (builtins.readFile ./nix/ensure-packaged.sh);
    };
    rubyLich = pkgs.callPackage ./nix/ruby-lich.nix {
      inherit fontsConf lichGems packagedSetup;
    };

    writeable = import ./nix/writeable.nix {inherit pkgs fontsConf toolchain lich-src;};
    packagedLich = pkgs.writeShellScriptBin "lich" (pkgs.lib.replaceStrings
      ["@launcher@" "@mode@" "@prepare@"]
      ["${rubyLich}" "packaged" "${packagedSetup}/bin/ensure-packaged"] (builtins.readFile ./nix/lich.sh));
    packaged = pkgs.symlinkJoin {
      name = "lich-packaged";
      paths = [rubyLich packagedLich];
      meta.mainProgram = "lich";
    };
  in {
    packages.${system} = {
      lich-gems = lichGems;
      lich-development-gems = developmentGems;
      bundix = lichBundix;
      ruby-lich = rubyLich;
      default = rubyLich;
      lich = packagedLich;
      inherit packaged;
      writeable = writeable.package;
      prepare-writeable = writeable.prepare;
    };

    apps.${system} = {
      ruby-lich = {
        type = "app";
        program = "${rubyLich}/bin/ruby-lich";
      };
      lich = {
        type = "app";
        program = "${packagedLich}/bin/lich";
      };
      writeable = {
        type = "app";
        program = "${writeable.package}/bin/lich";
      };
      prepare-writeable = {
        type = "app";
        program = "${writeable.prepare}/bin/prepare-writeable";
      };
    };

    # Dependency maintenance must work even when the packaged gems cannot
    # build yet, and must not inherit the frozen runtime configuration.
    devShells.${system} = {
      gem-tools = pkgs.mkShell {
        packages = [pkgs.ruby_4_0 lichBundix];
        shellHook = ''
          unset BUNDLE_GEMFILE BUNDLE_PATH BUNDLE_WITH BUNDLE_WITHOUT GEM_HOME GEM_PATH
          export BUNDLE_IGNORE_CONFIG=1
          export BUNDLE_FROZEN=0
          export BUNDLE_FORCE_RUBY_PLATFORM=1
        '';
      };

      writeable = pkgs.mkShell {
        packages = [writeable.package] ++ toolchain.buildTools ++ toolchain.assets;
        buildInputs = toolchain.libraries;
        shellHook =
          pkgs.lib.replaceStrings
          ["@launcher@" "@preload@" "@defaultGems@"]
          [
            "${writeable.ruby}/bin/ruby-lich"
            "${./nix/gem-user-dir.rb}"
            "${pkgs.ruby_4_0}/${pkgs.ruby_4_0.gemPath}"
          ]
          (builtins.readFile ./bin/writeable-hook.sh);
      };

      default = pkgs.mkShell {
        packages =
          [developmentGems.wrappedRuby developmentGems pkgs.pkg-config lichBundix]
          ++ toolchain.libraries ++ toolchain.assets;

        shellHook = ''
          source ${./bin/hook.sh}
          unset BUNDLE_PATH BUNDLE_WITH BUNDLE_WITHOUT
          export BUNDLE_IGNORE_CONFIG=1
          export BUNDLE_FROZEN=1
          export BUNDLE_GEMFILE="${developmentGems.confFiles}/Gemfile"
          export GEM_HOME="${developmentGems}/${pkgs.ruby_4_0.gemPath}"
          export GEM_PATH="$GEM_HOME"
          export FONTCONFIG_FILE="${fontsConf}"
          export LICHNIX_REV="${lich-src.rev}"
        '';
      };
    };

    # It's possible we want to just refactor to use pytest.
    checks.${system} = {
      maintenance-helpers =
        pkgs.runCommand "lich-maintenance-helpers-check" {
          nativeBuildInputs = [pkgs.python3 pkgs.bash];
          LICHNIX_MAINTENANCE_BIN = "${./bin}";
        } ''
          python3 ${./tests/test_maintenance_scripts.py}
          touch "$out"
        '';
      upstream-gemset =
        pkgs.runCommand "lich-upstream-gemset-check" {
          nativeBuildInputs = [lichBundix pkgs.nix];
        } ''
          export HOME="$TMPDIR" BUNDLE_IGNORE_CONFIG=1
          cp ${./nix/gems/gemset.nix} gemset.nix
          chmod u+w gemset.nix
          bundix --gemfile=${lich-src}/Gemfile --lockfile=${lich-src}/Gemfile.lock
          # Compare metadata rather than formatting of the generated Nix file.
          nix-instantiate --eval --strict --json ${./nix/gems/gemset.nix} > committed.json
          nix-instantiate --eval --strict --json gemset.nix > generated.json
          cmp committed.json generated.json
          touch "$out"
        '';
      packaged-preparation =
        pkgs.runCommand "lich-packaged-preparation-check" {
          nativeBuildInputs = [pkgs.python3 pkgs.bash pkgs.git pkgs.coreutils];
          PACKAGED_TEMPLATE = "${./nix/ensure-packaged.sh}";
        } ''
          python3 ${./tests/test_packaged_preparation.py}
          touch "$out"
        '';
      writeable-preparation =
        pkgs.runCommand "lich-writeable-preparation-check" {
          nativeBuildInputs = [pkgs.python3 pkgs.bash pkgs.git];
          PREPARE_TEMPLATE = "${./nix/prepare-writeable.sh}";
        } ''
          python3 ${./tests/test_writeable_preparation.py}
          touch "$out"
        '';
      writeable-launcher =
        pkgs.runCommand "lich-writeable-launcher-check" {
          nativeBuildInputs = [pkgs.python3];
          RUBY_LICH = "${writeable.ruby}/bin/ruby-lich";
          LICH = "${writeable.lich}/bin/lich";
        } ''
          python3 ${./tests/test_writeable_runtime.py}
          touch "$out"
        '';
      launcher =
        pkgs.runCommand "lich-launcher-check" {
          nativeBuildInputs = [pkgs.python3];
          RUBY_LICH = "${rubyLich}/bin/ruby-lich";
          LICH = "${packagedLich}/bin/lich";
        } ''
          python3 ${./tests/test_ruby_lich.py}
          touch "$out"
        '';
    };
  };
}
