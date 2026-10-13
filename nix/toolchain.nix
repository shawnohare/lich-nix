{pkgs}: {
  # Shared by both modes. The writeable mode also retains build tools after setup,
  # since community scripts and upstream recovery may compile additional gems.
  buildTools = with pkgs;
    [ruby_4_0 pkg-config stdenv.cc gnumake]
    # Ruby's debug-enabled extension builds invoke dsymutil on macOS.
    ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [pkgs.llvmPackages.llvm];
  libraries = with pkgs; [
    # Core native dependencies
    libffi
    libyaml
    ncurses
    openssl
    sqlite
    zlib
    gettext

    # GTK native libraries and bindings' build dependencies
    cairo
    gdk-pixbuf
    glib
    gobject-introspection
    gtk3
    pango

    # Additional transitive pkg-config dependencies
    expat
    libdatrie
    libepoxy
    libpthread-stubs
    libsysprof-capture
    libthai
    libxdmcp
    pcre2
  ];
  assets = with pkgs; [
    # GTK graphical runtime assets
    adwaita-icon-theme
    hicolor-icon-theme
    librsvg
    shared-mime-info
  ];
}
