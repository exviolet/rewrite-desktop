# CLAUDE.md

## Project Overview

Rewrite Desktop — Tauri v2 обёртка для browser SPA [rewrite](https://github.com/exviolet/rewrite). Web-приложение подключено как git submodule в `web/`.

## Architecture

```
rewrite-desktop/
├── web/                    # git submodule → rewrite (browser SPA)
├── src-tauri/
│   ├── src/
│   │   ├── lib.rs          # Tauri entry point
│   │   └── main.rs         # binary entry
│   ├── capabilities/
│   │   └── default.json    # Tauri v2 permissions
│   ├── icons/              # иконки приложения
│   ├── tauri.conf.json     # конфигурация Tauri
│   └── Cargo.toml
├── com.rewrite.app.desktop  # .desktop файл для Linux
├── install.sh                  # установка в ~/.local/
├── uninstall.sh                # удаление
├── package.json
└── .gitmodules
```

## Commands

```bash
bun dev           # Запуск Vite dev server + Tauri window
bun run build     # Production build (web + Rust бинарник)
bun update-web    # Обновить web submodule до последней версии

./install.sh      # Установить бинарник + .desktop + иконку в ~/.local/
./uninstall.sh    # Удалить
```

## Key Decisions

- **Два репозитория**: browser SPA не засоряется Rust/Tauri кодом, desktop развивается независимо
- **Submodule**: фиксирует конкретную версию web — desktop всегда собирается от стабильного коммита
- **isTauri + dynamic import()**: все Tauri JS-пакеты загружаются только в десктопе, браузерная версия не трогается
- **decorations: false**: нативный title bar убран, TabBar с drag-region и window controls
- **IndexedDB**: работает в Tauri WebView как в браузере
- **Дистрибуция**: бинарник + install.sh, без auto-update и CI (1–3 пользователя)

## Tauri Permissions

Минимальные права: только чтение/запись текстовых файлов в домашней директории и стандартных папках (Desktop, Documents, Downloads, Temp). Нет доступа к сети, процессам и т.д.

## Workflow

- Feature-ветки от `dev`: `git switch -c feat/name`
- Коммиты: русские, Conventional Commits (`feat(scope): описание`)
- HANDOFF.md **не включать** в коммиты
- Предпочитать `git switch` вместо `git checkout`
- После изменений в web/: коммитить в web/ submodule сначала, затем обновить указатель в desktop
