// @ts-check
import { defineConfig } from "astro/config";

// Страница статическая и самодостаточная: никаких внешних запросов в рантайме.
// Шрифты приезжают пакетами и раздаются со своего домена — у посетителя нет
// обращения к Google Fonts. Это не догма редактора (граница no-egress — про webview),
// а обычная гигиена: меньше зависимостей от чужого аптайма.
export default defineConfig({
  site: "https://sendoff-editor.pages.dev",
  output: "static",
  build: {
    inlineStylesheets: "auto",
  },
});
