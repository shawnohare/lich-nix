# lich-nix

A Nix development environment and standalone Ruby launcher for running
[Lich 5](https://github.com/elanthia-online/lich-5), the Ruby scripting engine
and game proxy for Simutronics' Gemstone IV and Dragonrealms. The development
environment should expose all dependencies to allow lich to run.

Currently targets Apple Silicon macOS (`aarch64-darwin`) with Ruby 4.0 and
tested against Lich v5.22.0. GTK dependencies successfully build and Lich GUI
runs and can be utilized by Saga.



## Development Setup

### Prerequisites

- Nix with flakes enabled
- Git

### 1. Clone this repository

```bash
git clone https://github.com/shawnohare/lich-nix.git
cd lich-nix
```

### 2. Enter the Nix development environment

```bash
nix develop
```

The flake provides Ruby 4.0, Bundler, and the native libraries and build tools
required by Lich.


### 3. Clone Lich 5 Source Repo

The upstream Lich source is maintained separately. We recommend using a stable
release version, which is automatically supplied by the `LICH_REV` variable in
our nix development shell.

```sh
git clone https://github.com/elanthia-online/lich-5.git "${LICH_SRC_HOME}"
cd "${LICH_SRC_HOME}"
git switch --detach ${LICH_REV}
```

Optionally, select a specific release tag for stability:

```bash
git fetch --tags
git tag --sort=-version:refname | head
git switch --detach <tag>
```

### 4. Install Ruby dependencies

Install dependencies locally, including the GTK group:

```bash
cd "${LICH_SRC_HOME}"
bundle install
```
This installs gems into the directory specified by BUNDLE_PATH in the Nix
development shell, without modifying Bundler's persistent local configuration.


### 5. Run Lich

The Nix development shell defines `lich` and `lichh` function that invokes Lich
through Bundler. Usage:

```bash
lich --version
lich --help
lich --help login
```

The function is equivalent to running:

```bash
bundle exec ruby ./upstream/lich-5/lich.rbw
```
The `lichh` function is the "lich headless" version that always passes `--no-gtk`.


### 6. Leaving and re-entering the environment

Exit the development shell with:

```bash
exit
```

To resume work:

```bash
cd lich-nix
nix develop
```

Ruby gems already installed are reused. There is no
need to rerun `bundle install` unless the upstream dependencies change.


## Launching Saga with the standalone Ruby launcher

[Saga](https://gswiki.play.net/Saga) is Simutronics' official GemStone IV
frontend. The `saga-ruby` Nix package lets Saga invoke the pinned Ruby 4.0
runtime with Bundler and GTK configured, even when Saga does not inherit from a
`nix develop` shell environment (i.e., is opened normally).

### 1. Install Lich and its gems

Complete the development setup above first. The launcher reuses the Lich
checkout and gems installed by `bundle install`; it does not package or
install them itself.

### 2. Build the launcher

The package definition lives in `nix/saga-ruby.nix`, with its shell template in
`nix/saga-ruby.sh`. Nix substitutes the pinned Ruby executable into the template
and wraps it with GTK runtime settings.

From this repository:

```sh
nix build .#saga-ruby
./result/bin/saga-ruby --version
```

Use the absolute path `<repo>/result/bin/saga-ruby` as Saga's Ruby executable.
Keep the `result` symlink: it protects the runtime from Nix garbage collection.
Rebuilding updates this symlink, so Saga can keep using the same path.

Alternatively, install into your Nix profile for a path independent of this
checkout:

```sh
nix profile add .#saga-ruby
```

The executable is then available at `~/.nix-profile/bin/saga-ruby`. Expand `~`
to your full home directory path when entering it in Saga.

### 3. Configure paths if needed

Defaults match the development shell:

| Setting | Default |
|---|---|
| `XDG_DATA_HOME` | `$HOME/.local/share` |
| `LICH_DATA_HOME` | `$XDG_DATA_HOME/lich-5` |
| `LICH_SRC_HOME` | `$LICH_DATA_HOME` |
| `BUNDLE_GEMFILE` | `$LICH_SRC_HOME/Gemfile` |
| `BUNDLE_PATH` | `$XDG_DATA_HOME/lich-nix/bundle` |

For custom paths, create `~/.config/lich-nix/runtime.sh` (or
`$XDG_CONFIG_HOME/lich-nix/runtime.sh`). The launcher sources this file as shell
code, so use only trusted configuration. For example:

```sh
export LICH_SRC_HOME="/absolute/path/to/lich-5"
export BUNDLE_PATH="/absolute/path/to/bundle"
```

These settings apply when Saga is launched from Finder as well. Inherited
environment variables also work; the configuration file takes precedence.
Use the same source and gem paths during `bundle install` in the development
shell. GTK remains enabled by default. For headless use, pass `--no-gtk` to
Lich; the launcher forwards all arguments unchanged and propagates Ruby's
exit status.

### 4. Configure Saga

Open Saga normally. If **Via Lich** is missing from the Connect pane, log in
using **Direct**, then enable `Menu > Session > Allow login with Lich`.

Select **Via Lich** and supply absolute paths:

| Setting | Path |
|---|---|
| Lich folder | Your Lich checkout, normally `/Users/<name>/.local/share/lich-5` |
| Ruby executable | `<repo>/result/bin/saga-ruby` or your profile's `bin/saga-ruby` |

Then proceed through Saga's login process. `bin/saga` and the older Ruby
wrappers remain available for development-shell testing.

## Current status and limitations

The standalone launcher supplies the pinned Ruby executable and GTK runtime
configuration, including fonts, icon themes, MIME data, and image loaders.
The checkout and installed gems remain outside the Nix store and writable.

Saga login was confirmed with Saga opened from Spotlight and its Ruby
executable set to the standalone launcher. A complete gameplay session still
needs manual verification. Ruby gems are not yet packaged with Nix: install them through
`bundle install` in the development shell and reinstall native extensions if
the pinned Ruby or native library dependencies change. Keep the development
shell dependencies available while using gems built against them, since those
external gems can reference Nix store paths outside the launcher's closure.


## TODO

### Installation and runtime layout

- [x] Support locating the Lich checkout under `~/.local/share/lich-5/` instead
  of requiring `upstream/lich-5`.
- [x] Make the Lich source directory configurable rather than assuming its
  location relative to this repository.
- [ ] Separate the application source from mutable runtime state, including
  credentials, saved logins, maps, scripts, databases, and logs. This might be
  tricky due to the fact that lich5 does not seem to expose a single env var
  controlling where it places application data.
- [x] Investigate a standalone Nix-provided Ruby launcher that can be executed
  by Saga without first launching Saga from a Nix shell.

### GTK support

- [x] Resolve the native Ruby `glib2` build failure involving the missing `sysprof-capture-4.pc` pkg-config dependency.
- [x] Install the complete `gtk` Bundler dependency group on Apple Silicon macOS.
- [ ] Verify Lich's native GTK launcher and GTK-dependent scripting functionality.
- [x] Retest Saga integration with GTK enabled and remove the temporary `--no-gtk` workaround.

See `docs/gtk_troubleshooting.md` for investigation notes.

### Development environments

- [ ] Retain a full default development shell (`nix develop`) including GTK, Ruby development tools, and test dependencies.
- [ ] Add a smaller headless/runtime shell (`nix develop .#headless`) without GTK dependencies.
- [ ] Share the same pinned Ruby 4 toolchain and common native dependencies across both shells.
- [ ] Determine which Ruby gems are strictly required for headless operation.

### Headless operation and frontend integration

- [ ] Establish a successful direct Lich character login from the CLI.
- [ ] Test `lich --login CHARACTER --headless 8000` without the Saga launcher.
- [ ] Connect VellumFE or ProfanityFE to the detached Lich session.
- [ ] Determine which functionality requires GTK and which is available with a headless proxy.
- [ ] Evaluate Saga's integration against the full GTK-enabled Lich runtime.

### Nix packaging

- [ ] Package Ruby gems using `bundix` and `bundlerEnv`.
- [ ] Create a Nix derivation for Lich itself.
- [ ] Provide a standalone `lich` executable using the packaged Ruby environment.
- [ ] Ensure all mutable application data resides outside the immutable Nix store.
