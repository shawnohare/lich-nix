# lich-nix

A Nix development environment for
[Lich 5](https://github.com/elanthia-online/lich-5), the Ruby scripting engine
and game proxy for Simutronics' Gemstone IV and Dragonrealms.

Currently targets Apple Silicon macOS (`aarch64-darwin`) with Ruby 4.0.

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
release version

```sh
git clone https://github.com/elanthia-online/lich-5.git "${LICH_SRC_HOME}"
cd "${LICH_SRC_HOME}"
```

Optionally, select a specific release tag for stability:

```bash
git fetch --tags
git tag --sort=-version:refname | head
git switch --detach <release-tag>
```

### 4. Install Ruby dependencies

Configure Bundler to install dependencies locally and exclude the GTK group:

```bash
cd "${LICH_SRC_HOME}"
BUNDLE_WITHOUT=gtk bundle install
```
This installs gems into the directory specified by BUNDLE_PATH in the Nix
development shell, without modifying Bundler's persistent local configuration.

The `gtk` group is excluded because native GTK Ruby bindings currently
encounter dependency issues on macOS with our pinned nixpkgs environment. This
setup targets Lich's headless runtime while retaining development tools such as
RSpec, RuboCop, and Ruby LSP.

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


## Launching Saga with Headless Lich (POC)

[Saga](https://gswiki.play.net/Saga) is Simutronics' official GemStone IV
frontend. It supports launching Lich directly, but our Nix-managed Ruby
environment requires some additional setup.

### 1. Expose Via Lich Login Option

If there is no "Via Lich" option in Saga's "Connect" pane, follow these steps.

Start Saga normally and login with the "Direct" option.
Toggle `Menu > Session > Allow login with Lich`. The Menu icon is likely in a
top corner.

### 2. Launch Saga with shell coxtext

In this repository's root, execute

```sh
bin/saga.sh
```
This wrapper locates the Saga executable in `/Applications` and opens it from a
nix development shell that has all of headless Lich's required dependencies.

Unlike `open -a Saga`, executing the binary directly allows Saga to inherit the
development shell's environment, including the Nix executable search path.

### 3. Configure Saga

Within Saga, select **Via Lich** from its login interface.

Supply these paths, replacing `<repo>` with the absolute path to the `lich-nix`
git checkout:

| Setting | Path |
|---|---|
| Lich folder | `<repo>/upstream/lich-5` |
| Ruby executable | `<repo>/bin/saga-ruby-headless-lich.sh` |

Do not use `~` in these fields; provide absolute paths.

Our ruby executable wrapper sets a few `BUNDLE_*` env vars and explicitly
passes in `--no-gtk` as an additional argument.

Then proceed through Saga's login process.

The approach above has been tested on Apple Silicon macOS. Saga
successfully launched and communicated with Lich, as evidenced by Lich
downloading scripts. Full gameplay functionality has not yet been validated.


## Current status and limitations

**Confirmed:** Launching Saga directly from `nix develop`, with the Nix-aware
Ruby wrapper, allows Saga to invoke Lich. Lich script downloads were observed.

**Not yet confirmed:** A complete, stable gameplay session with all Lich
scripting and graphical features operational.

This approach is intended as a development proof of concept, not a final
installation mechanism.

Current limitations:

- Saga must be launched from the Nix development environment so the wrapper can find `nix`.
- The Ruby wrapper enters `nix develop` each time Saga invokes it.
- The wrapper assumes Saga launches the Lich script using the expected argument convention.
- GTK is disabled because its Ruby bindings have not yet been successfully built.
- Native Lich GTK windows and GTK-dependent script features are unavailable.

A future Nix package should provide a standalone executable wrapper that does
not depend on an interactive development shell.

## TODO

### Installation and runtime layout

- [ ] Support locating the Lich checkout under `~/.local/share/lich-5/` instead
  of requiring `upstream/lich-5`.
- [ ] Make the Lich source directory configurable rather than assuming its
  location relative to this repository.
- [ ] Separate the application source from mutable runtime state, including
  credentials, saved logins, maps, scripts, databases, and logs. This might be
  tricky due to the fact that lich5 does not seem to expose a single env var
  controlling where it places application data.
- [ ] Investigate a standalone Nix-provided Ruby launcher that can be executed
  by Saga without first launching Saga from a Nix shell.

### GTK support

- [ ] Resolve the native Ruby `glib2` build failure involving the missing `sysprof-capture-4.pc` pkg-config dependency.
- [ ] Install the complete `gtk` Bundler dependency group on Apple Silicon macOS.
- [ ] Verify Lich's native GTK launcher and GTK-dependent scripting functionality.
- [ ] Retest Saga integration with GTK enabled and remove the temporary `--no-gtk` workaround.

See `docs/gtk-troubleshooting.md` for investigation notes.

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
