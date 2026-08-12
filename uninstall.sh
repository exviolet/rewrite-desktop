set -e

rm -f ~/.local/bin/sendoff-desktop
rm -f ~/.local/share/icons/hicolor/256x256/apps/sendoff.png
rm -f ~/.local/share/applications/dev.sendoff.app.desktop

rm -f ~/.local/bin/rewrite-desktop
rm -f ~/.local/share/icons/hicolor/256x256/apps/rewrite.png
rm -f ~/.local/share/applications/com.rewrite.app.desktop

rm -f ~/.local/bin/rewritebox-desktop
rm -f ~/.local/share/icons/hicolor/256x256/apps/rewritebox.png
rm -f ~/.local/share/applications/com.rewritebox.app.desktop

# Каталог данных НЕ трогаем намеренно: удаление приложения не должно уносить
# накопленные табы. Путь — ~/.local/share/dev.sendoff.app (прежде com.rewrite.app).
echo "Sendoff удалён. Данные остались в ~/.local/share/dev.sendoff.app."
