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

The flake provides Ruby 4.0, Bundler, packaged Ruby gems (including GTK,
curses, development, and editor dependencies), and native libraries and build
tools. Nix builds or retrieves the gems automatically; no `bundle install` is
needed.


### 3. Set up the Lich 5 repo checkout

From this repository run:

```sh
bin/sync-lich-checkout
```

The helper clones Lich if the destination is missing or empty, then switches
it to the exact revision pinned by this flake.

### 4. Run Lich (as a test)

The Nix development shell defines `lich` and `lichh` function that invokes Lich
through Bundler. Usage:

```bash
lich --version
```

The `lichh` function is the "lich headless" version that always passes `--no-gtk`.


## Launching Saga with the standalone Ruby launcher

[Saga](https://gswiki.play.net/Saga) is Simutronics' official GemStone IV
frontend. The `saga-ruby` Nix package lets Saga invoke the pinned Ruby 4.0
runtime with Bundler and GTK configured, even when Saga does not inherit from a
`nix develop` shell environment (i.e., is opened normally).

### 1. Install Lich

Clone the pinned Lich release as described above. The launcher packages Ruby
and its gems; the Lich checkout and application data remain writable files
outside the Nix store.

### 2. Build the launcher

The package definition lives in `nix/saga-ruby.nix`, with its shell template in
`nix/saga-ruby.sh`. Nix substitutes the pinned Ruby executable and packaged gem
environment into the template and wraps it with GTK runtime settings. The runtime includes the
`default`, `gtk`, and `profanity` gem groups.

From this repository:

```sh
nix build .#saga-ruby
./result/bin/saga-ruby --version
```

Use the absolute path `<repo>/result/bin/saga-ruby` as Saga's Ruby executable.
Keep the `result` symlink: it protects the runtime from Nix garbage collection.
Rebuilding updates this symlink, so Saga can keep using the same path.

their application data; tracked local edits block the switch.
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

For custom paths, set environment variables before launching the process that
uses the Ruby launcher. For example, in a terminal:

```sh
export LICH_SRC_HOME="/absolute/path/to/lich-5"
```

The launcher respects inherited environment variables. Saga opened from Finder
or Spotlight generally does not inherit exports from your terminal and will use
the defaults unless its launch environment supplies these variables. The
launcher fixes `BUNDLE_GEMFILE`, `GEM_HOME`, and `GEM_PATH` to the packaged
dependency set and ignores local Bundler configuration and `BUNDLE_PATH`. These
are no longer runtime customization settings. GTK remains enabled by default.
For headless use, pass `--no-gtk` to Lich; the launcher forwards all arguments
unchanged and propagates Ruby's exit status.

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
The checkout and application data remain outside the Nix store and writable;
the Ruby gems are now immutable Nix packages. Keeping the launcher in a Nix
profile or through the `result` symlink also retains its referenced gems and
native runtime libraries through garbage collection.

The packaged dependency set targets the pinned Lich release. Updating the
writable checkout independently does not update its Nix-managed gems. Scripts
that install additional gems dynamically cannot modify this immutable bundle;
add required gems to the package and rebuild. Existing gems under
`~/.local/share/lich-nix/bundle` are unused and are not removed automatically.

## Maintaining Ruby dependencies

Run these helpers from any directory. Each script in `bin/` contains detailed
comments describing its commands and the files it changes.

- [`bin/update-gems`](bin/update-gems) updates all gems allowed by the current
  Gemfile, regenerates `gemset.nix`, and builds and checks the runtime. Pass
  gem names to limit the update, for example `bin/update-gems sqlite3`.
- [`bin/update-lich-dependencies`](bin/update-lich-dependencies) handles a Lich
  release bump. First edit the tag in `inputs.lich-src.url` in `flake.nix`, then
  run this helper. It updates the Lich input lock, copies the new Gemfile
  **from the pinned source in the Nix store**, resolves required gem changes
  while preserving existing versions where possible, and builds and checks.
- [`bin/sync-lich-checkout`](bin/sync-lich-checkout) creates your writable Lich
  clone for initial setup or switches it to the pinned commit after a release bump. It uses the
  environment variables/default paths or an explicit checkout path, preserves
  application data, and refuses tracked local edits. Verify Lich/Saga manually
  afterward.
- [`bin/check-runtime`](bin/check-runtime) builds the launcher and development
  gems and runs the flake checks without updating dependencies.

The dependency files under `nix/gems/` are a Gemfile snapshot, Bundler's
resolved `Gemfile.lock`, and the generated `gemset.nix`. Entering `nix develop`
does not refresh them or switch your writable Lich clone. Review and commit
changed dependency files together; for a Lich release bump, include
`flake.nix` and `flake.lock` too. Do not run `bundle install` against the
packaged environment.

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

- [x] Package Ruby gems using `bundix` and `bundlerEnv`.
- [ ] Create a Nix derivation for Lich itself.
- [ ] Provide a standalone `lich` executable using the packaged Ruby environment.
- [ ] Ensure all mutable application data resides outside the immutable Nix store.
