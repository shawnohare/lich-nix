{
  pkgs,
  fontsConf,
  toolchain,
  lich-src,
}: let
  inherit (pkgs) lib;
  # Capture Nix's native build flags once, not through a shell at every login.
  # Literal store references in this output retain headers, SDKs, and libraries.
  nativeTools =
    pkgs.runCommand "lich-writeable-toolchain" {
      nativeBuildInputs = toolchain.buildTools;
      buildInputs = toolchain.libraries;
    } ''
      mkdir -p "$out"
      for setting in PKG_CONFIG_PATH NIX_CFLAGS_COMPILE NIX_LDFLAGS NIX_CC NIX_BINTOOLS SDKROOT MACOSX_DEPLOYMENT_TARGET CC CXX; do
        if [[ -v $setting ]]; then
          printf 'export %s=%q\n' "$setting" "''${!setting}" >> "$out/env.sh"
        fi
      done
      # Outside stdenv, compiler wrappers need their host role to read those flags.
      # Use the wrapper's own suffix, which differs from the Nix system name.
      printf 'export NIX_CC_WRAPPER_TARGET_HOST_${pkgs.stdenv.cc.suffixSalt}=1\n' >> "$out/env.sh"
      printf 'export NIX_BINTOOLS_WRAPPER_TARGET_HOST_${pkgs.stdenv.cc.suffixSalt}=1\n' >> "$out/env.sh"
      printf 'export PATH=%q:"$PATH"\n' '${lib.makeBinPath toolchain.buildTools}' >> "$out/env.sh"
    '';
  rubyScript = pkgs.writeShellScript "writeable-ruby" (lib.replaceStrings
    ["@ruby@" "@preload@" "@toolchain@" "@toolchainId@" "@defaultGems@"]
    [
      "${pkgs.ruby_4_0}/bin/ruby"
      "${./gem-user-dir.rb}"
      "${nativeTools}"
      (builtins.substring 11 12 (toString nativeTools))
      "${pkgs.ruby_4_0}/${pkgs.ruby_4_0.gemPath}"
    ]
    (builtins.readFile ./writeable-ruby.sh));
  ruby = pkgs.callPackage ./gtk-launcher.nix {
    inherit fontsConf;
    script = rubyScript;
    pathPackages = toolchain.buildTools;
  };
  lich =
    pkgs.writeShellScriptBin "lich" (lib.replaceStrings
      ["@launcher@" "@mode@" "@prepare@"] ["${ruby}" "writeable" "true"] (builtins.readFile ./lich.sh));
  runtime = pkgs.symlinkJoin {
    name = "lich-writeable-runtime";
    paths = [ruby lich];
    meta.mainProgram = "lich";
  };
  prepare = pkgs.writeShellApplication {
    name = "prepare-writeable";
    runtimeInputs = [pkgs.nix pkgs.coreutils pkgs.git];
    text =
      lib.replaceStrings ["@runtime@" "@bash@" "@lichRev@"]
      ["${runtime}" "${pkgs.bash}/bin/bash" (lib.escapeShellArg lich-src.rev)] (builtins.readFile ./prepare-writeable.sh);
  };
in {
  inherit ruby lich prepare;
  package = pkgs.symlinkJoin {
    name = "lich-writeable";
    paths = [runtime prepare];
    meta.mainProgram = "lich";
  };
}
