{
  lib,
  runCommand,
  wrapGAppsHook3,
  gtk3,
  gobject-introspection,
  librsvg,
  adwaita-icon-theme,
  hicolor-icon-theme,
  shared-mime-info,
  script,
  fontsConf,
  pathPackages ? [],
}:
# Build-time wrapping shared by the packaged and writable Ruby launchers.
runCommand "ruby-lich" {
  nativeBuildInputs = [wrapGAppsHook3];
  buildInputs = [
    gtk3
    gobject-introspection
    librsvg
    adwaita-icon-theme
    hicolor-icon-theme
    shared-mime-info
  ];
  meta.mainProgram = "ruby-lich";
} ''
  mkdir -p "$out/bin"
  cp ${script} "$out/bin/ruby-lich"
  chmod +x "$out/bin/ruby-lich"
  gappsWrapperArgsHook
  gappsWrapperArgs+=(
    --prefix PATH : "${lib.makeBinPath pathPackages}"
    --set FONTCONFIG_FILE "${fontsConf}"
    --prefix XDG_DATA_DIRS : "${lib.makeSearchPath "share" [
    adwaita-icon-theme
    hicolor-icon-theme
    shared-mime-info
  ]}"
  )
  wrapGApp "$out/bin/ruby-lich"
''
