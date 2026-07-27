<div align="center">

<img src="icon.svg" alt="Rewrite Desktop" width="112" height="112" />

# Rewrite Desktop

**Native desktop wrapper for [Rewrite](https://github.com/exviolet/rewrite) — built on Tauri v2.**

<img src="https://img.shields.io/badge/license-MIT-8b5cf6?style=for-the-badge" alt="License MIT" />
<img src="https://img.shields.io/badge/platform-Linux-c4b5fd?style=for-the-badge" alt="Platform: Linux" />
<img src="https://img.shields.io/badge/status-personal_project-2a2650?style=for-the-badge" alt="Status: personal project" />

English · [Русский](README.ru.md)

</div>

This repo is the thin native shell around the [Rewrite](https://github.com/exviolet/rewrite)
web app (included here as a git submodule). For what Rewrite *is* — the
prompt-first workflow, features, and screenshots — read the
[**web README**](https://github.com/exviolet/rewrite#readme). This file only
covers building and installing the native binary.

## What the wrapper adds

- Native file dialogs (open / save / import / export).
- Custom title bar with window controls.
- Reopen closed tabs (`Ctrl+Shift+T`).
- Global toast notifications.
- `tmux` integration via `tauri-plugin-shell` — send (`Ctrl+Enter`), target
  picker (`Ctrl+Shift+Enter`), and per-tab window binding. The desktop build's
  reason to exist.
- [Orca ADE](https://github.com/stablyai/orca) integration — bind a tab to an
  Orca agent and `Ctrl+Enter` sends the prompt into that agent's terminal
  instead of a tmux pane.

Everything else is the full browser feature set.

## Permissions

The webview gets a deliberately narrow shell surface: `tmux`, and `orca-ide`
scoped to four read/send subcommands. No arbitrary process spawning, no network
egress from the editor — home-directory file access is only safe because of
that. See `src-tauri/capabilities/default.json`.

## Requirements

- [Bun](https://bun.sh/) ≥ 1.0
- [Rust](https://rustup.rs/) (stable)
- Tauri system dependencies (Linux):
  - **Arch**: `webkit2gtk-4.1`, `gtk3`, `libsoup3`
  - **Ubuntu/Debian**: `libwebkit2gtk-4.1-dev`, `libgtk-3-dev`, `libsoup-3.0-dev`

> Linux-only by design. No Windows/macOS builds, no auto-update.

## Setup

```bash
git clone --recurse-submodules https://github.com/exviolet/rewrite-desktop.git
cd rewrite-desktop
bun install
```

## Develop

```bash
bun dev      # Vite dev server + Tauri window
```

## Build & install

```bash
bun run build:bin   # build just the binary (tauri build --no-bundle)
./install.sh        # install to ~/.local/ (binary + .desktop + icon)
./uninstall.sh      # remove
```

`build:bin` skips AppImage/deb bundling (it relies on `linuxdeploy` and isn't
needed for a `~/.local/bin` install). The full `bun run build` may fail on
`linuxdeploy` on some machines — you don't need it for installing.

After `install.sh` the app shows up in rofi / your app launcher.

## Update an installed copy

```bash
./update.sh   # git pull + sync web submodule + build:bin + install
```

Pulls `master`, checks out the pinned `web/` submodule commit, rebuilds the
binary, and reinstalls in one step. Restart the app from your launcher after.

## Updating the web submodule (dev)

```bash
bun update-web                                  # bump web/ to its latest commit
git add web && git commit -m "chore: bump web submodule"
```

## Status

A personal tool on `v0.1.x`, used daily on Linux. Public as a portfolio piece —
**it works for me, but no support or stability is guaranteed.**

Honest scope: Linux-only, built from source (no prebuilt release yet), no
auto-update, no tests, and issues may sit. Contributions aren't being
solicited — fork freely instead.

## License

[MIT](LICENSE)
