#!/bin/bash
set -e

BINARY="src-tauri/target/release/rewrite-desktop"
ICON="src-tauri/icons/icon.png"
DESKTOP="com.rewrite.app.desktop"

if [ ! -f "$BINARY" ]; then
  echo "Бинарник не найден. Сначала запусти: bun run build"
  exit 1
fi

mkdir -p ~/.local/bin
mkdir -p ~/.local/share/applications
mkdir -p ~/.local/share/icons/hicolor/256x256/apps

cp "$BINARY" ~/.local/bin/rewrite-desktop
chmod +x ~/.local/bin/rewrite-desktop

cp "$ICON" ~/.local/share/icons/hicolor/256x256/apps/rewrite.png

sed "s|Exec=rewrite-desktop|Exec=$HOME/.local/bin/rewrite-desktop|" "$DESKTOP" \
  > ~/.local/share/applications/com.rewrite.app.desktop

echo "Rewrite установлен:"
echo "  Бинарник: ~/.local/bin/rewrite-desktop"
echo "  Иконка:   ~/.local/share/icons/hicolor/256x256/apps/rewrite.png"
echo "  Desktop:  ~/.local/share/applications/com.rewrite.app.desktop"
echo ""
echo "Убедись что ~/.local/bin есть в PATH."
