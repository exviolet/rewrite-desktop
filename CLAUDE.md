# CLAUDE.md

## Project Overview

RewriteBox Desktop — Tauri v2 обёртка для browser SPA [rewritebox](https://github.com/exviolet/rewritebox). Web-приложение подключено как git submodule в `web/`.

## Architecture

```
rewritebox-desktop/
├── web/                    # git submodule → rewritebox (browser SPA)
├── src-tauri/
│   ├── src/
│   │   ├── lib.rs          # Tauri entry point
│   │   └── main.rs         # binary entry
│   ├── capabilities/
│   │   └── default.json    # Tauri v2 permissions
│   ├── icons/              # иконки приложения
│   ├── tauri.conf.json     # конфигурация Tauri
│   └── Cargo.toml
├── package.json
└── .gitmodules
```

## Commands

```bash
bun dev           # Запуск Vite dev server + Tauri window
bun build         # Production build (web + Rust бинарник)
bun update-web    # Обновить web submodule до последней версии
```

## Key Decisions

- **Два репозитория**: browser SPA не засоряется Rust/Tauri кодом, desktop развивается независимо
- **Submodule**: фиксирует конкретную версию web — desktop всегда собирается от стабильного коммита
- **Zero frontend changes** (Step 1–3): web работает в Tauri WebView без модификаций
- **IndexedDB**: работает в Tauri WebView как в браузере

## Workflow

- Feature-ветки от `dev`: `git switch -c feat/name`
- Коммиты: русские, Conventional Commits (`feat(scope): описание`)
- HANDOFF.md **не включать** в коммиты
- Предпочитать `git switch` вместо `git checkout`
