{
  lib,
  writeShellScript,
  callPackage,
  ruby_4_0,
  fontsConf,
  lichGems,
  packagedSetup,
}: let
  # Packaged mode forces the Nix snapshot; writeable mode uses a separate template.
  script = writeShellScript "ruby-lich" (lib.replaceStrings
    ["@ruby@" "@gemfile@" "@gemhome@" "@prepare@"]
    [
      "${ruby_4_0}/bin/ruby"
      "${lichGems.confFiles}/Gemfile"
      "${lichGems}/${ruby_4_0.gemPath}"
      "${packagedSetup}/bin/ensure-packaged"
    ]
    (builtins.readFile ./ruby-lich.sh));
in
  callPackage ./gtk-launcher.nix {
    inherit script fontsConf;
    pathPackages = [lichGems.wrappedRuby lichGems];
  }
