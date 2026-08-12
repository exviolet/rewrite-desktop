<div align="center">

<img src="icon.svg" alt="Sendoff Desktop" width="112" height="112" />

# Sendoff Desktop

**Native desktop wrapper for [Sendoff](https://github.com/exviolet/sendoff-web) — built on Tauri v2.**

<img src="https://img.shields.io/badge/license-MIT-8b5cf6?style=for-the-badge" alt="License MIT" />
<img src="https://img.shields.io/badge/platform-Linux-c4b5fd?style=for-the-badge" alt="Platform: Linux" />
<img src="https://img.shields.io/badge/status-personal_project-2a2650?style=for-the-badge" alt="Status: personal project" />

English · [Русский](README.ru.md)

</div>

This repo is the thin native shell around the [Sendoff](https://github.com/exviolet/sendoff-web)
web app (included here as a git submodule). For what Sendoff *is* — the
prompt-first workflow, features, and screenshots — read the
[**web README**](https://github.com/exviolet/sendoff-web#readme). This file only
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
- [Herdr](https://herdr.dev) integration — same idea, bound to a Herdr agent
  pane. Herdr persists pane ids, so unlike tmux and Orca the binding survives a
  server restart or a reboot. **Needs Herdr ≥ 0.7**: pane ids changed shape after
  0.6 (`w657cefe818690a-1` → `wK:p1`), and the older form is rejected by the
  command allowlist — sending fails with a message that blames the permission
  rather than the version.
- One target picker for all three (`Ctrl+Shift+Enter`), sectioned by source; a
  source that is not running simply has no section.
- Live agent status in the status bar — a quiet dot while the agent works, a
  visible label only when it is blocked waiting for your answer.
- Exactly one instance runs: launching again exits immediately instead of opening
  a second window. Two copies on one database would quietly eat each other's
  work — a save rewrites the whole snapshot, so the instance with the staler view
  wins and deletes whatever the other one created. The second launch does ask the
  existing window to come forward, but Wayland compositors ignore an activation
  request from a process you did not just interact with, so nothing visibly
  happens there — measured on niri, both from the AppImage and from a source
  build.

Everything else is the full browser feature set.

## Permissions

The webview gets a deliberately narrow shell surface: `tmux`, plus `orca-ide`
and `herdr` scoped to individual read/send subcommands. Scoping matters most for
`herdr`: the same binary can also run arbitrary processes and tear down sessions,
so it is allowlisted per subcommand rather than wholesale. No arbitrary process
spawning, no network egress from the editor — home-directory file access is only safe because of
that. See `src-tauri/capabilities/default.json`.

## Download

Grab the AppImage from the [latest release](https://github.com/exviolet/sendoff/releases/latest):

```bash
chmod +x Sendoff_*_amd64.AppImage
./Sendoff_*_amd64.AppImage
```

Needs **glibc ≥ 2.35** — Ubuntu 22.04+, Debian 12+, Fedora 36+, Arch. It is built
in a container on Ubuntu 22.04 for exactly that reason; an AppImage bundles its
libraries but *not* glibc, so building on a rolling distro would produce a file
that only runs on rolling distros.

It expects a normal desktop system for the handful of libraries AppImage
deliberately does not bundle (X11/Wayland, OpenGL, fontconfig, freetype). Any
Linux desktop has them; a bare container does not.

> ⚠️ **Don't mix the AppImage and a source build on the same machine.** Both use
> the same data directory, but the AppImage bundles WebKitGTK 2.50 while a current
> distribution ships 2.52+. From 2.52 on, WebKit writes IndexedDB in a new metadata
> format and **silently upgrades the database the first time it opens it** — after
> which the AppImage can no longer read it, and shows an empty editor plus a storage
> error. Your data is intact and is never overwritten: when Sendoff cannot read, it
> stops writing altogether. Go back to whichever build you were using before and
> your tabs are there. The incompatibility is one-way — newer WebKit reads older
> databases, not the other way round.

No auto-update — to upgrade, download the new AppImage, or build from source and
use `./update.sh`.

## Requirements (building from source)

- [Bun](https://bun.sh/) ≥ 1.0
- [Rust](https://rustup.rs/) (stable)
- Tauri system dependencies (Linux):
  - **Arch**: `webkit2gtk-4.1`, `gtk3`, `libsoup3`
  - **Ubuntu/Debian**: `libwebkit2gtk-4.1-dev`, `libgtk-3-dev`, `libsoup-3.0-dev`

> Linux-only by design. No Windows/macOS builds, no auto-update.

## Setup

```bash
git clone --recurse-submodules https://github.com/exviolet/sendoff.git
cd sendoff-desktop
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

`build:bin` skips AppImage/deb/rpm bundling — you don't need them for a
`~/.local/bin` install. The full `bun run build` produces all three.

After `install.sh` the app shows up in rofi / your app launcher.

### Release artifacts

Release AppImages are built inside a container so they stay usable on older
distributions (see [Download](#download) for why):

```bash
docker build -t sendoff-appimage-builder .
docker run --rm -v "$PWD":/src -u "$(id -u):$(id -g)" -e HOME=/tmp \
  -e CARGO_TARGET_DIR=/src/src-tauri/target-docker \
  sendoff-appimage-builder bash -lc 'bun install && bun run build'
```

The artifact lands in `src-tauri/target-docker/release/bundle/appimage/`. Only
the AppImage is published: the `.deb` and `.rpm` come out of the same build but
have never been installed on a Debian or Fedora system, and shipping untested
packages is a promise this project cannot back.

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

Honest scope: Linux-only, x86_64 only, no auto-update, and issues may sit. Tests
cover pure logic and the IndexedDB layer only. Contributions aren't being
solicited — fork freely instead.

## License

[MIT](LICENSE)
