# Rewrite Roadmap

> Долгоживущий документ. Источник правды по позиционированию, приоритетам и явным отказам. Обновляется по мере принятия решений в сессиях.

## Позиционирование

**Rewrite — prompt-first editor для быстрой формулировки LLM-промптов.** Возник из конкретной боли: маленький input в Claude Code + неудобный scroll в tmux при долгих сессиях.

**Не является:** pipeline-builder, knowledge base (Obsidian/Notion), code editor (VS Code/Vim).

**Целевой flow:** написал промпт в Rewrite → отправил в активную tmux pane (см. фичу #1) → продолжил в Claude Code.

## Цели проекта

| Приоритет | Цель |
|---|---|
| Primary | Личный инструмент + опыт работы с Tauri/Rust |
| Secondary | Портфолио |
| Не цель | OSS-продукт с поддержкой (модель: public repo, лицензия, README с дисклеймером «works for me, no support») |

**Следствия:**
- Можно делать breaking changes без миграций (solo dev, ранняя стадия).
- Не нужны: auto-update, CI-релизы, Windows/macOS билды, i18n, CONTRIBUTING.md, issue templates.
- README/polish — до уровня портфолио, без maintain-обязательств.
- При выборе «полировать для юзеров» vs «экспериментировать с Tauri» — выбирать второе.

## Экосистема

Под брендом `exviolet/rewrite-*`:

- **`rewrite`** — web SPA (existing). React + Zustand + Vite.
- **`rewrite-desktop`** — Tauri v2 wrapper (existing). Прошёл dogfooding (75+ табов, ежедневное использование).
- **`rewrite-cli`** — будущий отдельный проект. Массовый LLM-powered text rewriter через пресеты (`rewrite file.txt --preset formal`). Старт **только после** того как GUI будет полностью дотянут до желаемого состояния. Shared core с GUI = preset engine + template engine + provider abstraction.
- **`rewrite-docs`** — будущий, документация.

## Roadmap GUI — приоритезированный

Зафиксировано в grill-сессии 2026-04-27.

| # | Фича | Файл задачи | Статус |
|---|---|---|---|
| 1 | tmux send-keys (Ctrl+Enter → активная tmux pane) | [tasks/01-tmux-send-keys.md](../tasks/01-tmux-send-keys.md) | done |
| 2 | Автоимя табов из первой строки + fuzzy-поиск + auto-cleanup пустых | [tasks/02-tab-organization.md](../tasks/02-tab-organization.md) | done |
| 3 | Tab Switcher Preview Panel | [tasks/03-tab-switcher-preview-panel.md](../tasks/03-tab-switcher-preview-panel.md) | done |
| 4 | Floating reference panel | [tasks/04-floating-reference-panel.md](../tasks/04-floating-reference-panel.md) | done |
| 5 | Bulk Find & Replace с preview | [tasks/05-bulk-find-replace-preview.md](../tasks/05-bulk-find-replace-preview.md) | done |
| 6 | Global Tab Search (`Ctrl+Shift+D`) | [tasks/06-global-tab-search.md](../tasks/06-global-tab-search.md) | done |
| 7 | Workspaces | — | conditional — **только если #2/#3/#6 не решат хаос 75 Untitled** |

Файлы задач создаются в `tasks/` по мере того как фича становится active. YAGNI: не создавать stub-файлы для будущих приоритетов заранее.

## Отложенные идеи (не сейчас, требуют предусловий)

- **Chained Presets** + **Live Preview Transformation** — это пивот в pipeline-builder, ломает позиционирование «prompt-first editor». Включать только если появятся реально сложные пресеты и подтверждённая потребность.
- **API integrations (DeepL, spell check)** — ломают strict local-first. Если делать — только opt-in per-preset + API keys в Tauri secret store + обновление threat model в CLAUDE.md (сейчас «нет доступа к сети»).
- **rewrite-cli** — после того как GUI будет в желаемом состоянии (см. Экосистема выше).

## Явные отказы

История решений «не делать», чтобы случайно не вернулись:

| Дата | Отказ | Причина |
|---|---|---|
| 2026-04-27 | `rewrite-vscode` | Противоречит концепции (Rewrite избегает code editors как UX-ответ на боль). Выпилен из экосистемы. |
| 2026-04-28 | Git-Flow (dev/release/hotfix ветки) | Overhead для solo dev на personal tool. Сам автор Git-Flow в 2020 рекомендовал GitHub Flow для CI/CD. Принят GitHub Flow: master + feature/*, --no-ff, атомарные коммиты, русские Conventional Commits. |
| 2026-04-28 | `.handoff/.decisions/.context/` dotdirs сразу | YAGNI. Один файл `HANDOFF.md` решает задачу. Split на директории — только когда HANDOFF реально перерастёт ~300 строк или появятся явно разные типы записей. |
| 2026-04-28 | Subagents для проекта | Tauri-обёртка одного SPA + редкие UX-фиксы — нет места для параллелизма. |
| 2026-04-28 | PostToolUse hook для tsc на каждый Edit/Write | Слишком медленно (5-10s на вызов). Заменено на PreToolUse(Bash:git commit) — verification только в момент коммита. |

## Open questions

Нерасковыранные грилл-ветви для будущих сессий:

- **Floating reference panel** — отдельное окно ОС vs panel в пределах главного окна. Технически разное, разный UX. Решить когда дойдёт очередь.
- **OSS-публикация механика** — какая лицензия (MIT?), формат README с дисклеймером, нужны ли скриншоты. Решить когда GUI закроет приоритеты #1–#3.
- **`rewrite-cli` архитектура** — что такое `@rewrite/core`. Какие функции реально shared между GUI и CLI. Решить перед стартом CLI.

## Известные ограничения

- **Системная тема через `gsettings color-scheme` / nwg-look** — применяется только после рестарта приложения. Это ограничение WebKitGTK на Linux, не наш баг. Смена через GTK-вариант темы (например Graphite → Graphite-Dark) работает мгновенно. Пользователь явно выбрал не реализовывать D-Bus listener (вариант 1 «оставить как есть»).
