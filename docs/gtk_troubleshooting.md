# Lich 5 on Nix: GTK Dependency Investigation

**Platform tested:** Apple Silicon macOS (`aarch64-darwin`)  
**Environment:** Nix development shell, Ruby 4.0.7, Bundler 4, GTK 3.24.52  
**Status:** GTK Ruby gems installed; standalone GTK window and Lich graphical
launcher started successfully. Some graphical runtime asset warnings were
subsequently improved.

## Executive summary

Getting Lich 5's GTK interface running under Nix on macOS required a more
complete native dependency set than the initial development shell supplied. The
recurring issue was that Ruby's `pkg-config` gem traversed transitive
dependencies declared in native libraries' `.pc` files—including
`Requires.private`—and failed when those packages' pkg-config metadata was not
visible, even though ordinary dynamic linking of the primary library could
work.

We resolved these failures by adding the relevant native development
dependencies to the Nix shell rather than patching upstream libraries, using
Homebrew, or modifying Ruby gems. After the native bindings installed, we
separately configured fonts, icon themes, and GdkPixbuf image loaders so the
GTK application could render properly.

## 1. Initial environment

The original flake provided Ruby 4.0.7, Bundler, `pkg-config`, `bundix`, and
native dependencies such as GTK 3, GLib, GObject Introspection, Cairo, Pango,
GdkPixbuf, SQLite, OpenSSL, libffi, libyaml, and zlib.

Ruby and Bundler worked, but `bundle install` failed on native extensions in
the GTK dependency tree. GTK was temporarily excluded through
`BUNDLE_WITHOUT=gtk` while investigating. The independent Ruby `curses` build
also failed until `ncurses` was added.

## 2. Recurring native-extension failure pattern

Across several gems, we observed the following sequence:

1. The extension configuration successfully detected its primary native library and version.
2. The Ruby `pkg-config` gem traversed the library's pkg-config dependency graph, including private dependencies.
3. A transitive `.pc` module could not be located in the shell's pkg-config search paths.
4. `extconf.rb` failed before producing a Makefile.
5. Adding the relevant Nix package made that module visible, allowing the installation to progress.

| Ruby gem or library chain | Missing pkg-config module | Nix dependency added | Outcome |
|---|---|---|---|
| `glib2` / GLib | `sysprof-capture-4` | `libsysprof-capture` | Resolved |
| GLib | `libpcre2-8` | `pcre2` | Resolved |
| `cairo` / XCB | `xdmcp` | `libxdmcp` | Resolved |
| `pango` | `libthai` | `libthai` | Resolved |
| LibThai | `datrie-0.2` | `libdatrie` | Resolved |
| `gtk3` | `epoxy` | `libepoxy` | Resolved |

We also added `libpthread-stubs` and `expat`, based on the dependency sets used
in nixpkgs' own Ruby GTK gem packaging. We did not isolate those two packages
as the sole cause of any individual failure.

**Interpretation:** These were predominantly missing development metadata or
transitive build dependencies, not demonstrated incompatibilities between Ruby
4, GTK, and macOS. The exact need for every dependency in a final runtime
closure has not been established.

## 3. Sysprof: the key diagnostic

The first GTK failure occurred while building `glib2` 4.3.6 against
Nix-provided GLib 2.88.3:

```text
PackageConfig::NotFoundError:
.pc doesn't exist: <sysprof-capture-4>
```

We inspected `glib-2.0.pc` and found:

```text
Requires.private: sysprof-capture-4 >= 3.38.0, libpcre2-8 >= 10.32
```

Ordinary linking succeeded:

```sh
pkg-config --libs glib-2.0
```

But traversal of static/private dependencies initially failed:

```sh
pkg-config --libs --static glib-2.0
```

We briefly tested a temporary override of `glib-2.0.pc` that removed the
Sysprof reference. That exposed `libpcre2-8` as the next missing module,
supporting the dependency-traversal diagnosis.

An attempt to install the full `sysprof` Nix package failed on Apple Silicon
macOS because it depended on `elfutils`, which nixpkgs marks as unsupported on
Darwin. The successful solution was to add **`libsysprof-capture`**, the
narrower native library package, instead. This removed the need for any
metadata patch.

## 4. Cairo, Pango, and GTK

The same failure pattern continued as installation advanced:

- **Cairo (`cairo` gem 1.18.5):** The library itself was detected, but a transitive XCB dependency required `xdmcp`. Inspecting `xcb.pc` confirmed `Requires.private: xau >= 0.99.2 xdmcp`. Adding `libxdmcp` and associated build dependencies resolved the blocker.
- **Pango (`pango` gem 4.3.6):** Pango 1.57.1 was detected, but `libthai` was absent. Adding `libthai` exposed another missing private dependency, `datrie-0.2`; adding `libdatrie` resolved it.
- **GTK (`gtk3` gem 4.3.6):** Cairo and GTK 3.24.52 were detected, but `epoxy` was missing. Adding `libepoxy` allowed the GTK gem installation to complete.

We repeatedly used checks such as:

```sh
pkg-config --modversion <module>
pkg-config --libs --static <library>
```

The `--static` check was a **diagnostic of transitive metadata resolution**,
not an indication that we intended to build statically linked GTK extensions.

## 5. Separate ncurses issue

The Ruby `curses` 1.6.0 gem failed to find linkable curses symbols even though
headers were detected:

```text
checking for ncursesw/curses.h... yes
checking for initscr() in -lncursesw... no
```

Adding `ncurses` to the development shell resolved this separate native linking
issue. Unlike the GTK-only dependencies, this also matters for the non-GTK gem
installation.

## 6. Font configuration

After the GTK gems installed, Ruby could load GTK 3.24.52, but reported:

```text
Fontconfig error: Cannot load default config file: File not found
```

A standalone GTK window opened, although the font initially looked poor. Adding
the Fontconfig package alone did not provide the expected usable configuration
at the initially assumed path.

We tested a configuration generated by `pkgs.makeFontsConf` using both macOS
font directories and Nix-managed DejaVu fonts. Both approaches worked;
**Nix-managed DejaVu** was preferred to reduce reliance on macOS-specific
directories when Linux support is added later.

Conceptually:

```nix
fontsConf = pkgs.makeFontsConf {
  fontDirectories = [
    pkgs.dejavu_fonts
  ];
};
```

And in the development shell:

```nix
shellHook = ''
  export FONTCONFIG_FILE="${fontsConf}"
'';
```

This configuration pins available fonts through the flake, although font
rendering can still differ by platform and display backend.

## 7. Icon themes and image loaders

With Lich's GTK launcher running, we encountered warnings such as:

```text
Could not load a pixbuf from
/org/gtk/libgtk/theme/Adwaita/assets/bullet-symbolic.svg
```

and:

```text
Could not find the icon 'missing-image-ltr'.
The 'hicolor' theme was not found either.
```

We added:

| Package | Purpose |
|---|---|
| `librsvg` | SVG image loading through GdkPixbuf |
| `hicolor-icon-theme` | Standard fallback icon theme |
| `adwaita-icon-theme` | GTK's usual icon assets |
| `shared-mime-info` | MIME type database |

We also configured `XDG_DATA_DIRS` and `GDK_PIXBUF_MODULE_FILE` so GTK could
find those resources. The changes appeared to help; we did not independently
prove that every package or variable was strictly necessary.

In a future fully packaged derivation, use Nixpkgs' GTK application wrapper
facilities where appropriate rather than assuming hand-maintained shell
environment variables are the optimal final implementation.


## 8. Three distinct dependency layers

1. **Native libraries:** GLib, GTK, Cairo, Pango, SQLite, OpenSSL, and other libraries needed for application functionality.
2. **Native build dependencies:** Compiler headers, pkg-config metadata, and transitive dependencies required when Ruby gems compile their extensions.
3. **Graphical runtime configuration:** Fonts, Fontconfig, icon themes, MIME data, and GdkPixbuf loaders required for a functional and correctly rendered GUI.

A Nix development shell exposes all three together. A fully packaged derivation
can distinguish build-time dependencies from runtime dependencies more
precisely and avoid carrying unnecessary development outputs into the
application runtime closure.

## 9. Verified outcomes

**Verified during this investigation:**

- Ruby 4.0.7 and Bundler worked in the Apple Silicon macOS Nix shell.
- The GTK Ruby dependency installation ultimately completed successfully.
- Ruby loaded GTK 3.24.52.
- A standalone GTK window opened.
- The Lich GTK launcher started.
- Fontconfig and GTK icon/image-loader configuration improved graphical operation.

## Conclusion

**We did not need to patch Lich, Ruby, GTK, or the Ruby gems to complete the
GTK dependency installation.** The primary obstacle was making the native
dependency graph and its pkg-config metadata available to the Ruby extension
builds. Once those builds succeeded, GTK also needed explicit configuration for
fonts, icon themes, and image loaders. The result is a working GTK-capable Lich
development setup on Apple Silicon macOS, with further runtime validation and
packaging cleanup still outstanding.
