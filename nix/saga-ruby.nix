{
  lib,
  runCommand,
  writeShellScript,
  wrapGAppsHook3,
  ruby_4_0,
  gtk3,
  gobject-introspection,
  librsvg,
  adwaita-icon-theme,
  hicolor-icon-theme,
  shared-mime-info,
  fontsConf,
  lichGems,
}:
let
  # The checkout remains writable; Ruby and its gems are Nix-managed.
  sagaRubyScript = writeShellScript "saga-ruby" (
    lib.replaceStrings
      [ "@ruby@" "@gemfile@" "@gemhome@" ]
      [ "${ruby_4_0}/bin/ruby" "${lichGems.confFiles}/Gemfile" "${lichGems}/${ruby_4_0.gemPath}" ]
      (builtins.readFile ./saga-ruby.sh)
  );
in
runCommand "saga-ruby" {
  nativeBuildInputs = [ wrapGAppsHook3 ];
  buildInputs = [
    gtk3
    gobject-introspection
    librsvg
    adwaita-icon-theme
    hicolor-icon-theme
    shared-mime-info
  ];
  meta.mainProgram = "saga-ruby";
} ''
  mkdir -p "$out/bin"
  cp ${sagaRubyScript} "$out/bin/saga-ruby"
  chmod +x "$out/bin/saga-ruby"
  # runCommand does not run the standard fixup phases automatically.
  gappsWrapperArgsHook
  gappsWrapperArgs+=(
    --prefix PATH : "${lib.makeBinPath [ lichGems.wrappedRuby lichGems ]}"
    --set FONTCONFIG_FILE "${fontsConf}"
    --prefix XDG_DATA_DIRS : "${lib.makeSearchPath "share" [
      adwaita-icon-theme hicolor-icon-theme shared-mime-info
    ]}"
  )
  wrapGApp "$out/bin/saga-ruby"
''
