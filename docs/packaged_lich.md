# Packaged Lich core and writable runtime

The source derivation `packages.aarch64-darwin.lich-source` installs core
libraries, the upstream entry point, license, dependency manifests, and
available initial assets. Tests, benchmarks, and development documentation are
excluded from the runtime output.

`packaged` includes `lich` and the GTK-wrapped `ruby-lich`. Their closure retains
the application source and pinned gem environment. First launch creates a home
at `$LICHNIX_DATA_HOME/runtime` without Git or network access. Lich
itself can still download scripts/data during normal startup or login.

## Source and state

The runtime home contains writable data, scripts, maps, logs, temporary files,
backups, and session coordination files. Initial scripts/data/assets, when
present in the source, are copied only when absent. Existing files and symlinks
are preserved. The pinned upstream tree currently has no initial scripts/data
directories; their contents still depend on upstream bootstrap/synchronization.

The home-relative `lich.rbw` and `lib` links point through `.lichnix-package`
to the immutable package. Setup checks these compatibility links before making
changes and refuses to replace unmanaged files at those two names. A lock
serializes setup; the package pointer is replaced atomically. Package upgrades
and rollbacks select core code without replacing mutable user files. They do
not roll back database schemas, downloaded scripts, or other application state.
Keep the selected package in a Nix profile or retain its build-result symlink;
the runtime home's links alone are not garbage-collection roots.

## Entry point and child processes

The packaged Ruby entry point loads the upstream application after resolving
and normalizing its directory flags. It sets writable defaults, supplies the
immutable `--lib-dir`, and adds the package to the load path for legacy
`require 'lib/...'` forms. A different library source requires writeable mode.

Resolved paths are exported for children. Explicit directory flags take
precedence; an explicit home resets inherited subdirectory defaults unless
those subdirectories are also explicitly supplied. Child entry points restore
omitted flags from the environment. The program name points to the home-relative
entry point for reconnect, persistent GUI launches, and `elogin`. The entry
point activates `bundler/setup` itself, so raw Ruby children use the same bundle
even when they bypass the shell launcher's Ruby options.

This policy assumes children retain the environment and use the packaged entry
point. It does not constrain arbitrary Ruby file writes, prevent environment
changes, or support a script replacing the home-relative entry point.

## Unsupported mutation features

Normal startup warns that Lich core self-update/rollback, engine replacement,
gem repair/refresh, and runtime gem additions are unsupported. The package does
not block these commands or patch upstream mutation APIs. They can attempt
downloads, modify writable files, and fail against store paths. Use Nix upgrades,
rollbacks, or dependency rebuilds; use writeable mode when upstream mutation
behavior is required. Script and data updates remain separate writable operations.

## Launchers

Writeable launchers use the distinct names `lich-w` and `ruby-lich-w` and default
to `$LICHNIX_DATA_HOME/src/lich-5`, allowing both modes in one Nix profile.

