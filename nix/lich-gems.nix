{ lib, bundlerEnv, ruby_4_0, lich-src, excludedGroups ? [ "development" "vscode" ] }:

let
  gemset = import ./gems/gemset.nix;
  # bundix records upstream's group membership; only exclusions are our policy.
  groups = lib.subtractLists excludedGroups
    (lib.unique (lib.concatMap (gem: gem.groups or [ "default" ]) (lib.attrValues gemset)));
in
bundlerEnv {
  name = "lich-gems";
  ruby = ruby_4_0;
  gemfile = "${lich-src}/Gemfile";
  lockfile = "${lich-src}/Gemfile.lock";
  inherit gemset groups;
}
