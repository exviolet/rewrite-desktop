set -e

BINARY="src-tauri/target/release/sendoff-desktop"
ICON="src-tauri/icons/icon.png"
DESKTOP="dev.sendoff.app.desktop"

if [ ! -f "$BINARY" ]; then
  echo "Бинарник не найден. Сначала запусти: bun run build"
  exit 1
fi

# Переезд каталога данных после переименования проекта (Rewrite → Sendoff, 2026-08-13).
# Каталог задаётся identifier'ом в tauri.conf.json, поэтому новый бинарь, запущенный без
# переноса, открыл бы ПУСТУЮ базу, а накопленное осталось бы лежать рядом невидимым.
#
# Живёт здесь, а не в update.sh, по двум причинам: install.sh лежит на ОБОИХ путях
# (dev `build:bin && ./install.sh` и консюмерский `update.sh`, который зовёт этот скрипт),
# и он выполняется уже ПОСЛЕ успешной сборки — перенос до сборки оставил бы упавшее
# обновление со старым бинарником и уехавшими данными.
OLD_DATA="$HOME/.local/share/com.rewrite.app"
NEW_DATA="$HOME/.local/share/dev.sendoff.app"
if [ -d "$OLD_DATA" ] && [ ! -d "$NEW_DATA" ]; then
  # Переносить каталог из-под работающего приложения нельзя. Хуже того, гард
  # single-instance держит DBus-имя ПО IDENTIFIER, а он меняется: старый бинарь и
  # новый друг друга не увидят и смогут работать одновременно на одной базе — это
  # ровно тот случай, ради которого гард и заводился (запись переписывает снапшот
  # целиком, отставший инстанс стирает чужое).
  if pgrep -x rewrite-desktop >/dev/null 2>&1 || pgrep -x sendoff-desktop >/dev/null 2>&1; then
    echo "!! Приложение запущено — закрой окно и повтори."
    echo "   Каталог данных переезжает (com.rewrite.app → dev.sendoff.app), и делать"
    echo "   это на живом инстансе нельзя. Установка прервана, ничего не тронуто."
    exit 1
  fi
fi
if [ -d "$OLD_DATA" ]; then
  if [ ! -d "$NEW_DATA" ]; then
    echo "→ перенос данных: com.rewrite.app → dev.sendoff.app…"
    mv "$OLD_DATA" "$NEW_DATA"
  else
    echo "!! Есть ОБА каталога данных:"
    echo "     старый: $OLD_DATA"
    echo "     новый:  $NEW_DATA"
    echo "   Новый, вероятно, создан запуском Sendoff до установки и пуст."
    echo "   Разберись руками, какой нужен, и удали лишний. Установка прервана."
    exit 1
  fi
fi

mkdir -p ~/.local/bin
mkdir -p ~/.local/share/applications
mkdir -p ~/.local/share/icons/hicolor/256x256/apps

cp "$BINARY" ~/.local/bin/sendoff-desktop
chmod +x ~/.local/bin/sendoff-desktop

cp "$ICON" ~/.local/share/icons/hicolor/256x256/apps/sendoff.png

sed "s|Exec=sendoff-desktop|Exec=$HOME/.local/bin/sendoff-desktop|" "$DESKTOP" \
  > ~/.local/share/applications/dev.sendoff.app.desktop

# Следы прежних имён проекта. Без этого в меню приложений остаётся лишний пункт,
# указывающий на бинарник, которого больше не собирают.
rm -f ~/.local/bin/rewrite-desktop \
      ~/.local/share/icons/hicolor/256x256/apps/rewrite.png \
      ~/.local/share/applications/com.rewrite.app.desktop

echo "Sendoff установлен:"
echo "  Бинарник: ~/.local/bin/sendoff-desktop"
echo "  Иконка:   ~/.local/share/icons/hicolor/256x256/apps/sendoff.png"
echo "  Desktop:  ~/.local/share/applications/dev.sendoff.app.desktop"
echo ""
echo "Убедись что ~/.local/bin есть в PATH."
