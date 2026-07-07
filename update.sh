#!/bin/bash
# update.sh — обновить установленный Rewrite до последнего master.
# Для консюмера: тянет desktop, выравнивает web-submodule на ЗАКОММИЧЕННЫЙ
# указатель (не бампит на свой master — это делает разработчик через
# `bun update-web`), собирает бинарь и переустанавливает в ~/.local/bin.
#
# Сборка через `build:bin` (= `tauri build --no-bundle`): только бинарь, без
# AppImage/deb — bundling пропускается, linuxdeploy не запускается (для install
# в ~/.local/bin бандл не нужен, а linuxdeploy на части машин падает).
set -e

cd "$(dirname "$0")"

echo "→ git pull (desktop, ff-only)…"
git pull --ff-only

echo "→ submodule update (web → закоммиченный указатель)…"
git submodule update --init --recursive

echo "→ bun install (на случай смены зависимостей)…"
bun install

echo "→ сборка бинаря (--no-bundle, без AppImage/linuxdeploy)…"
bun run build:bin

echo "→ установка…"
./install.sh

echo "✓ Rewrite обновлён до $(git rev-parse --short HEAD). Перезапусти приложение из меню."
