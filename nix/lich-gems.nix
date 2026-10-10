{ bundlerEnv, ruby_4_0, groups ? [ "default" "gtk" "profanity" ] }:

bundlerEnv {
  name = "lich-gems";
  ruby = ruby_4_0;
  gemdir = ./gems;
  inherit groups;
}
