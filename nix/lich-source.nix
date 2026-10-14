{ lib, runCommand, lich-src }:
runCommand "lich-5-${builtins.substring 0 12 lich-src.rev}" {
  meta = {
    description = "Pinned Lich core with a writable runtime-home entry point";
    license = lib.licenses.bsd3;
    platforms = ["aarch64-darwin"];
  };
} ''
  destination="$out/share/lich-5"
  mkdir -p "$destination"
  cp -R ${lich-src}/lib "$destination/lib"
  cp ${lich-src}/lich.rbw "$destination/upstream.rbw"
  cp ${lich-src}/LICENSE ${lich-src}/Gemfile ${lich-src}/Gemfile.lock "$destination/"
  for asset in scripts data maps logo.png fly64.ico; do
    if [ -e "${lich-src}/$asset" ]; then
      cp -R "${lich-src}/$asset" "$destination/$asset"
    fi
  done
  cp ${./packaged-entry.rb} "$destination/lich.rbw"
  cp ${./packaged-state.rb} "$destination/packaged-state.rb"
  printf '%s\n' '${lich-src.rev}' > "$destination/revision"
''
