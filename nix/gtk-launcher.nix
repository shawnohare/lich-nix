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
  program ? "ruby-lich",
}:
# Build-time wrapping shared by the packaged and writable Ruby launchers.
runCommand program {
  nativeBuildInputs = [wrapGAppsHook3];
  buildInputs = [
    gtk3
    gobject-introspection
    librsvg
    adwaita-icon-theme
    hicolor-icon-theme
    shared-mime-info
  ];
  meta.mainProgram = program;
} ''
  mkdir -p "$out/bin"
  cp ${script} "$out/bin/${program}"
  chmod +x "$out/bin/${program}"
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
  wrapGApp "$out/bin/${program}"
''
