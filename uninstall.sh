#!/bin/bash
set -e

rm -f ~/.local/bin/rewrite-desktop
rm -f ~/.local/share/icons/hicolor/256x256/apps/rewrite.png
rm -f ~/.local/share/applications/com.rewrite.app.desktop

# Legacy (RewriteBox)
rm -f ~/.local/bin/rewritebox-desktop
rm -f ~/.local/share/icons/hicolor/256x256/apps/rewritebox.png
rm -f ~/.local/share/applications/com.rewritebox.app.desktop

echo "Rewrite удалён."
