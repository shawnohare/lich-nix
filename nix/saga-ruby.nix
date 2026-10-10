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
}:
let
  # Gems and the Lich checkout remain writable, user-managed files.
  sagaRubyScript = writeShellScript "saga-ruby" (
    lib.replaceStrings [ "@ruby@" ] [ "${ruby_4_0}/bin/ruby" ]
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
    --prefix PATH : "${lib.makeBinPath [ ruby_4_0 ]}"
    --set FONTCONFIG_FILE "${fontsConf}"
    --prefix XDG_DATA_DIRS : "${lib.makeSearchPath "share" [
      adwaita-icon-theme hicolor-icon-theme shared-mime-info
    ]}"
  )
  wrapGApp "$out/bin/saga-ruby"
''
