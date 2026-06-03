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
| 8 | tmux target picker (`Ctrl+Shift+Enter` → выбор session/window/pane с именами) | [tasks/07-tmux-picker.md](../tasks/07-tmux-picker.md) | done |
| 9 | tmux tab-binding (таб → окно по `session:window` имени, цепочка Explicit→Last→Modal) | — | queued — после догфуда #8 |
| 10 | Pin/unpin табов (`Ctrl+P` = pin/toggle, command palette → `Ctrl+Shift+P`) | — | queued |
| 11 | Reference panel → live tab (указать на живой таб вместо снапшота; замена split-view) | — | queued |

Файлы задач создаются в `tasks/` по мере того как фича становится active. YAGNI: не создавать stub-файлы для будущих приоритетов заранее.

### Решения grill-сессии 2026-06-03 (tmux deep integration + tab UX)

- **Split-view отклонён** — дублирует существующую reference panel (`Ctrl+R`, уже side-by-side) и дрейфует в code-editor/IDE (анти-позиционирование). Заменён на #11: апгрейд reference panel до указания на живой таб.
- **tmux tab-binding (#9) биндит по имени `session:window`, НЕ по `@id`.** Window/pane `@id` эфемерны — ресетятся при рестарте tmux-сервера (ребут), поэтому persistent-привязка к `@id` протухает ровно как global-last (который сознательно НЕ персистится). Дескриптор `{session_name, window_name}` резолвится живьём в момент отправки; если окно не найдено → модалка + toast. Цена: давать агентским окнам стабильные имена (`tmux rename-window claude`).
- **«Active pane» как тихий дефолт `Ctrl+Enter` уходит в #9.** Цепячка резолва — Explicit (tab-binding) → Last (global, in-memory) → Modal (fallback). «Active pane» остаётся лишь пунктом *внутри* модалки. В #8 `Ctrl+Enter` пока не трогается (чисто аддитивная фаза).
- **Persistence split (#9):** tab-binding → IndexedDB (переживает ребут); last-global-target → Zustand in-memory (протухает с сессией, персистить вредно).
- **Settings (#9):** два тумблера (`remember last globally` = on, `auto-bind on pick` = off) — захардкодить дефолтами, выносить в Settings-UI только если догфуд покажет потребность флипать. Не строить панель под пустоту.

## Отложенные идеи (не сейчас, требуют предусловий)

- **Chained Presets** + **Live Preview Transformation** — это пивот в pipeline-builder, ломает позиционирование «prompt-first editor». Включать только если появятся реально сложные пресеты и подтверждённая потребность.
- **API integrations (DeepL, spell check)** — ломают strict local-first. Если делать — только opt-in per-preset + API keys в Tauri secret store + обновление threat model в CLAUDE.md (сейчас «нет доступа к сети»).
- **ACP / MCP / agent-runner внутри Rewrite** (запуск Claude Code, Codex, Gemini CLI и т.п. с UI «Agent → Action → Source → Run → diff → Apply», как в Pencil.dev / Zed). **Не сейчас** по трём причинам: (1) ломает позиционирование «prompt-first editor» в сторону «agent-in-editor» — Cursor/Zed/Continue/Aider уже занимают эту нишу, Rewrite станет bad Cursor; (2) ломает threat model «no network, no processes» — потребует Tauri permissions на сеть/процессы, провайдер-абстракцию, секретный store для ключей, diff/cancel/retry; это второй продукт внутри Rewrite размером с сам Rewrite; (3) не решает текущий реальный pain «написать ответ затратно» — это решение для другой задачи (применить AI-трансформацию к тексту), которой у пользователя нет (шаблонами в Ctrl+K не пользуется). **Условия включения:** появится конкретный кейс из реальных сессий, где «run agent inside Rewrite → diff → apply» явно выигрывает у текущего `Ctrl+Enter → Claude Code в tmux` flow. Зафиксировано как parked / future exploration, не как вечный отказ.
- **Context-mediator между tmux-агентами** (отдельный процесс/файл, собирающий контекст о проекте и инжектящий его в каждый агентский запуск). **Не сейчас:** knowledge-base direction (отказ в позиционировании), дублирует существующие `CLAUDE.md` / `AGENTS.md` (которые оба агента уже читают), требует filesystem access за пределы Rewrite. Future research note, не roadmap item.
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

- **tmux-отправка в TUI с эвристикой «вставка vs ввод» (codex и подобные)** —
  требует `paste-buffer -p` (bracketed paste) + settle-задержку перед `send-keys
  Enter`, иначе приложение глотает Enter как часть пасты и сабмит не происходит
  (первый раз проходит по гонке, повторные виснут). Исправлено в `useTmuxSend`
  (2026-06-03). Claude Code / pi.dev работали и без `-p`.

- **Системная тема через `gsettings color-scheme` / nwg-look** — применяется только после рестарта приложения. Это ограничение WebKitGTK на Linux, не наш баг. Смена через GTK-вариант темы (например Graphite → Graphite-Dark) работает мгновенно. Пользователь явно выбрал не реализовывать D-Bus listener (вариант 1 «оставить как есть»).
