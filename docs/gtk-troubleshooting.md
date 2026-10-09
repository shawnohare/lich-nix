# Lich 5: GTK and Native Gem Troubleshooting on macOS

**Status:** Unresolved GTK dependency; headless Ruby dependencies successfully installed.

**Environment:** Apple Silicon macOS (`aarch64-darwin`), Nix development shell, Ruby 4.0.

## 1. Background

The `lich-nix` project aims to provide a reproducible Nix development environment for [Lich 5](https://github.com/elanthia-online/lich-5), a Ruby scripting engine and proxy for Simutronics' GemStone IV.

The longer-term goal is to support both:

- A full development/runtime environment, including GTK-based graphical functionality.
- An optional lightweight, headless environment for running Lich as a background process with an external front end.

**We do not want to permanently remove GTK.** Some Lich utilities and scripts may depend on graphical functionality. Although headless operation is useful, it is not necessarily a complete replacement.

## 2. Initial environment

The project uses a Nix flake targeting `aarch64-darwin` with the `nixpkgs-unstable` input pinned through `flake.lock`.

At the time of testing:

| Component | Version |
|---|---|
| Ruby | 4.0.7 |
| Bundler | 4.0.20, automatically switched to lockfile version 4.0.6 |
| GLib | 2.88.3 |
| GTK | GTK 3 |
| Ruby GTK bindings | `gtk3` 4.3.6 |
| Ruby GLib bindings | `glib2` 4.3.6 |
| Ruby curses bindings | `curses` 1.6.0 |

The initial development shell included:

```nix
packages = with pkgs; [
  ruby_4_0
  pkg-config
  bundix

  gtk3
  gobject-introspection
  glib
  cairo
  pango
  gdk-pixbuf
  sqlite
  openssl
  libffi
  libyaml
  zlib
];
```

Later, `ncurses` was added.

The Lich 5 source is cloned into `upstream/lich-5`, while Bundler installs gems into `upstream/.bundle`.

## 3. Failure #1: GTK's `glib2` Ruby extension

### Reproduction

From the Lich source checkout, with all runtime dependency groups enabled:

```bash
bundle install
```

Bundler successfully installed numerous dependencies but failed while compiling the `glib2` gem.

Relevant output:

```text
Installing glib2 4.3.6 with native extensions

checking for Homebrew... yes
checking for gobject-2.0 version (>= 2.56.0)...
yes (2.88.3)

*** extconf.rb failed ***

PackageConfig::NotFoundError:
.pc doesn't exist: <sysprof-capture-4>
```

The reported dependency chain was:

```text
gtk3 (4.3.6)
  └── atk (4.3.6)
       └── glib2 (4.3.6)
            └── Native GLib dependency resolution
                 └── Missing sysprof-capture-4.pc
```

### Investigation

The following commands were executed inside the Nix development environment:

```bash
which pkg-config
pkg-config --modversion glib-2.0
pkg-config --variable=pcfiledir glib-2.0
pkg-config --exists sysprof-capture-4
echo $?
```

Results:

```text
/nix/store/...-pkg-config-wrapper-0.29.2/bin/pkg-config

2.88.3

/nix/store/...-glib-2.88.3-dev/lib/pkgconfig

1
```

These results establish:

1. The shell uses Nix's pkg-config wrapper.
2. GLib 2.88.3 is being located inside the Nix store.
3. `sysprof-capture-4` cannot be resolved through the current pkg-config search paths.

The Ruby extension also printed `checking for Homebrew... yes`, but that alone does not establish that Homebrew libraries caused the failure.

**Working hypothesis:** The GLib pkg-config metadata references `sysprof-capture-4` as a private dependency. Ruby's `pkg-config` gem traverses this metadata and fails because that dependency is unavailable.

This is consistent with a missing or incorrectly exposed pkg-config dependency, not necessarily a missing runtime library.

The precise `.pc` metadata contents and whether the dependency is required for linking the extension have not yet been inspected.

## 4. Attempted fix: provide Sysprof through Nix

The initial proposal was to add `sysprof` to the development shell, assuming it would supply `sysprof-capture-4.pc`.

We tested:

```bash
nix build nixpkgs#sysprof --no-link
```

The build failed during evaluation:

```text
error: Refusing to evaluate package 'elfutils-0.195'
because it is not available on the requested hostPlatform:

hostPlatform.system = "aarch64-darwin"
```

The attempted Sysprof package was version 50.0.

The `nixpkgs#sysprof` command also resolved through the user's configured Determinate Nix registry, not necessarily the exact nixpkgs revision pinned by the `lich-nix` flake.

### Conclusion

Adding the complete `sysprof` package is not currently a viable fix on Apple Silicon macOS because its dependency graph includes Linux-only `elfutils`.

We deliberately did not enable `allowUnsupportedSystem` or force unsupported packages to build.

**Unresolved:** Whether the smaller Sysprof capture library can be provided independently, or whether GTK/GLib can be compiled with the Sysprof integration disabled.

## 5. Headless dependency experiment

Because GTK was the failing dependency, we temporarily excluded its Bundler group:

```bash
bundle config set --local without "gtk"
bundle install
```

This replaced a previous local `without` setting of `development:vscode`.

Consequently, the development and editor tooling dependency groups were now included, while GTK was excluded.

The build progressed beyond `glib2`, confirming that the previous failure was associated with the GTK dependency group.

However, a second native gem failure occurred.

## 6. Failure #2: Ruby `curses` extension

Relevant output:

```text
Installing curses 1.6.0 with native extensions

checking for tgetent() in -ltinfow... no
checking for tgetent() in -ltinfo... no
checking for tgetent() in -ltermcap... no

checking for ncursesw/curses.h... yes
checking for initscr() in -lncursesw... no

checking for ncurses.h... yes
checking for initscr() in -lncursesw... no
checking for initscr() in -lncurses... no

checking for curses.h... yes
checking for initscr() in -lcurses... no

*** extconf.rb failed ***
```

The compiler could locate relevant header files but could not successfully link a curses library exposing `initscr()`.

### Fix

Added `ncurses` to the Nix development shell:

```nix
packages = with pkgs; [
  # Existing dependencies...
  ncurses
];
```

After re-entering the Nix shell and rerunning:

```bash
bundle install
```

the installation succeeded:

```text
Bundle complete! 41 Gemfile dependencies,
64 gems now installed.

Gems in the group 'gtk' were not installed.
```

This establishes that `ncurses` resolved the immediate native extension failure.

## 7. Current working state

The current Nix development shell successfully provides:

- Ruby 4.0.7.
- Bundler.
- SQLite, OpenSSL, ncurses, and the other currently required native libraries.
- Lich's non-GTK Ruby dependencies.
- Development tools including RSpec, RuboCop, and Ruby LSP.

The GTK Bundler group remains excluded through the local Bundler configuration:

```bash
bundle config set --local without "gtk"
```

Lich's CLI help executes:

```bash
bundle exec ruby lich.rbw --no-gtk --help
```

The application also accepts a `--no-gtk` argument, which avoids GTK initialization.

Running Lich without a configured login has not yet established that a complete game session works.

A successful game login, persistent proxy operation, and external front-end connection remain to be tested.

## 8. Possible next investigations

### A. Inspect GLib's pkg-config metadata

Start with:

```bash
pkg-config --variable=pcfiledir glib-2.0
```

Then inspect the actual `glib-2.0.pc` file, especially its `Requires.private` field.

Determine:

- Which dependency declares `sysprof-capture-4`.
- Whether it is genuinely required for the Ruby native extension.
- Whether it was introduced by the selected GLib version or Nix build configuration.

### B. Investigate the Nix GLib derivation

Examine the GLib derivation in the exact nixpkgs revision pinned by `flake.lock`.

Check whether the Sysprof dependency can be disabled or whether another output provides the needed pkg-config metadata.

A targeted package override may be preferable to changing system-wide Nix settings.

### C. Investigate the Ruby `glib2` build

The Ruby `glib2` gem uses `pkg-config` during native extension compilation.

Determine why its dependency resolution requires `sysprof-capture-4`, including whether it is traversing `Requires.private` unnecessarily for this build.

A fix may be possible at the Ruby gem configuration layer.

### D. Test a localized pkg-config workaround

One proposed workaround is a Nix derivation that provides modified GLib `.pc` metadata without the unresolved Sysprof dependency.

This has not been implemented or validated.

Such a workaround should only be used if removing the dependency does not hide an actual required link-time dependency.

### E. Validate GTK runtime functionality

Once GTK gems compile, test:

```bash
bundle exec ruby -e 'require "gtk3"; puts "GTK loaded"'
```

Then test the Lich launcher and GTK-dependent scripts.

Successful compilation alone is insufficient to establish that GTK initializes and works correctly on macOS.

## 9. Notes for future maintainers or coding agents

- Do not remove GTK permanently merely because headless mode currently builds.
- Keep Ruby 4.0 as an explicit requirement.
- Do not introduce Homebrew dependencies unless a native Nix solution proves impractical.
- Do not enable unsupported nixpkgs packages simply to bypass platform restrictions.
- Use the project's pinned nixpkgs input when investigating dependency overrides.
- Maintain a distinction between GTK libraries provided by Nix and the corresponding Ruby GTK gems managed by Bundler.
- Preserve the current functional non-GTK setup while investigating graphical support.

**Primary unresolved issue:** Building the Ruby `glib2` 4.3.6 extension against Nix-provided GLib 2.88.3 on `aarch64-darwin` fails because `sysprof-capture-4.pc` cannot be resolved.

**Next recommended action:** Inspect GLib's actual pkg-config metadata and its nixpkgs derivation before attempting further dependency additions or overrides.
