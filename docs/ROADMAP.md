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
- ~~**`rewrite-cli`**~~ — **отклонён 2026-06-16.** LLM-powered text rewriter out of scope (сеть/API-ключи ломают local-first), shared с GUI ~10 строк — `@rewrite/core` преждевременен. См. «Терминальные таргеты + обратная связь».
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
| 9 | tmux tab-binding (таб → окно по `session:window` имени, цепочка Explicit→Last→Modal) | [tasks/08-tmux-tab-binding.md](../tasks/08-tmux-tab-binding.md) | done |
| 10 | Pin/unpin табов (`Ctrl+P` = pin/toggle, command palette → `Ctrl+Shift+P`) | [tasks/09-pin-unpin-tabs.md](../tasks/09-pin-unpin-tabs.md) | done |
| 11 | Reference panel → live tab (указать на живой таб вместо снапшота; замена split-view) | [tasks/10-reference-live-tab.md](../tasks/10-reference-live-tab.md) | **paused / under review** (реализация есть, дизайн под вопросом) |

Файлы задач создаются в `tasks/` по мере того как фича становится active. YAGNI: не создавать stub-файлы для будущих приоритетов заранее.

### #11 reference live-tab — paused / under review (2026-06-11)

Codex реализовал tasks/10 полностью (tsc + lint exit 0), но при ревью дизайн
вызвал сомнения. **Не мержим, не выпиливаем** — код сохранён на ветке web
`feature/reference-live-tab` (коммит `70d9f6c`, не в `master`). Возврат к решению
о судьбе фичи — отложен (отдельный разговор про будущее Rewrite). README
сознательно **не** документируют live-tab, пока он не смержен.

### Решения grill-сессии 2026-06-03 (tmux deep integration + tab UX)

- **Split-view отклонён** — дублирует существующую reference panel (`Ctrl+R`, уже side-by-side) и дрейфует в code-editor/IDE (анти-позиционирование). Заменён на #11: апгрейд reference panel до указания на живой таб.
- **tmux tab-binding (#9) биндит по имени `session:window`, НЕ по `@id`.** Window/pane `@id` эфемерны — ресетятся при рестарте tmux-сервера (ребут), поэтому persistent-привязка к `@id` протухает ровно как global-last (который сознательно НЕ персистится). Дескриптор `{session_name, window_name}` резолвится живьём в момент отправки; если окно не найдено → модалка + toast. Цена: давать агентским окнам стабильные имена (`tmux rename-window claude`).
- **«Active pane» как тихий дефолт `Ctrl+Enter` уходит в #9.** Цепячка резолва — Explicit (tab-binding) → Last (global, in-memory) → Modal (fallback). «Active pane» остаётся лишь пунктом *внутри* модалки. В #8 `Ctrl+Enter` пока не трогается (чисто аддитивная фаза).
- **Persistence split (#9):** tab-binding → IndexedDB (переживает ребут); last-global-target → Zustand in-memory (протухает с сессией, персистить вредно).
- **Settings (#9):** два тумблера (`remember last globally` = on, `auto-bind on pick` = off) — захардкодить дефолтами, выносить в Settings-UI только если догфуд покажет потребность флипать. Не строить панель под пустоту.

## Консолидация v0.2 (hardening, 2026-06-14)

Backlog приоритетов #1–#10 закрыт, #11 запаркован — точка перегиба
«консолидировать», а не «добавлять фичи». Подтверждено внешним ревью (5 моделей
OpenAI/Google/Anthropic, отзывы в репо не хранятся): самый когерентный совет —
«перестань добавлять фичи, выпусти v0.2 на укрепление».
После v0.2 — старт `rewrite-cli` (см. Экосистема).

Находки отфильтрованы под цели проекта (личный инструмент + Tauri + портфолио,
**не** коммерческий продукт). Отброшены как «мерили не тем аршином»: «нет
тестов/CI» (противоречит контракту), «узкая ниша не выживет», «native textarea
ceiling», «поддержка других терминалов». Фантом: full-text search «линейный скан»
— поиск по ~75 in-memory строкам, не IndexedDB-скан, на масштабе не проблема.

| Tier | Пункт | Статус |
|---|---|---|
| 1 | web README → desktop-first (tmux требует desktop-сборку) | **done** (web `13614ed`) |
| 1 | undo/redo Map cleanup при закрытии таба | **done** |
| 1 | IndexedDB error-handling + toast при сбое load/save | **done** |
| 1 | Скриншот/GIF в README (портфолио) | **done** (демо-GIF на плоском фоне, web `9a9802c`) |
| 2 | Persistence diff-save (только изменённые/удалённые сущности) | **отклонён — фантом** (замер 2026-06-16, см. Явные отказы) |
| 2 | Декомпозиция `App.tsx` / `editorStore` (~400 строк) | **done** (web merge `a7aa058`: App 397→257, editorStore 427→316) |

Tier 1 и Tier 2 закрыты. Бонусом — фикс tab-order persistence (DnD reorder
переживает рестарт, `tabOrder` в meta, web merge `589724e`). Из активного roadmap
остаётся только #11 live-tab (paused). GUI консолидирован.

## Терминальные таргеты + обратная связь (решения 2026-06-14, ревизия 2026-06-16)

**Herdr — candidate target (без кода, испытательный срок ~1 неделя).** Новый
мультиплексор для агентов с нормальным CLI/API: `pane list`, `pane read`,
`pane send-text`/`send-keys`/`run` — реальный кандидат во вторую реализацию рядом
с tmux. Решение: `TerminalTarget`-абстракцию **не строить заранее**. Пользователь
тестирует Herdr неделю; если приживётся в agent-workflow — абстракцию вводим **в
момент второй реализации**, не раньше (split-when-needed: извлечь интерфейс из
одного impl при добавлении второго дёшево). Если Herdr CLI окажется
tmux-совместимым — поддержка почти бесплатна.

**2a (Capture bound pane → Reference) — ЗАКРЫТО (spike 2026-06-16).** Голый
zero-code тест `tmux capture-pane -S -200 -p` на реальном TUI-агенте (Claude Code)
показал: capture возвращает **весь отрендеренный экран TUI** (tool-calls, глифы
`●`/`※`/рамки, статусбар, прошлые промпты), а не чистый последний ответ. Чтобы
вытащить ответ — нужен хрупкий per-agent парсинг (Claude Code/Codex/pi рендерят
по-разному). Авто-capture **проигрывает** ручному Ctrl+R/manual paste ровно на
целевых таргетах (TUI-агенты). Herdr `pane read` это **не спасает** — читает тот
же отрендеренный пейн (проблема в TUI-репейнте, не в backend). Цена выяснения: 0
строк кода, 0 новых permission, 0 расширения threat model. Permission
`capture-pane` **не вводим**.

**rewrite-cli / rewrite-agent — НЕ строим (решение 2026-06-16).**
- **LLM-powered CLI** (`rewrite file.txt --preset formal`, provider abstraction,
  API-ключи, сеть) — out of scope. Реально шарит с GUI только `assemblePrompt()` +
  тип `PromptTemplate` (~10 строк + дата); ради этого `@rewrite/core` / монорепо —
  инфраструктура без жильцов. Провайдер-слой — net-new, не «вынесли общее».
- **rewrite-agent** (`send`/`list-targets`/`capture` как отдельный бинарь) —
  `send`/`list-targets` GUI уже делает in-process через `tauri-plugin-shell`
  (бинарь = дублирование через границу процесса без потребителя); `capture` —
  единственное новое, провалило spike выше. Жильца на отдельный бинарь нет.

GUI остаётся clipboard/local/terminal-agent oriented: без backend, без API-ключей,
без прямых LLM-вызовов. Self-run AI / Live Preview Transformation остаются parked
(см. «Отложенные идеи»).

**Salvage-кандидат (backlog, НЕ начинаем): `capture-as-input`.** Перевёрнутое
направление — выдернуть **не-TUI** вывод (ошибки компилятора, stack trace, лог,
`git diff`) **в промпт, который пишешь** (для линейного вывода scrape чистый,
TUI-проблемы нет). На позиционировании (prompt-first подтягивает контекст). Но
это **отдельная фича со своим жильцом**, не reference-mirror. Нужен реальный кейс
из ежедневного потока + проверка, что бьёт «выделил в терминале → Ctrl+Shift+C →
вставил». Зафиксировано как кандидат, не решение.

**Sequencing (ревизия 2026-06-16):** rewrite-cli/agent ветка закрыта → возврат к
GUI: судьба #11 (live-tab), Tier 2 (persistence diff-save, декомпозиция
`App.tsx`/`editorStore`).

## Отложенные идеи (не сейчас, требуют предусловий)

- **Chained Presets** + **Live Preview Transformation** — это пивот в pipeline-builder, ломает позиционирование «prompt-first editor». Включать только если появятся реально сложные пресеты и подтверждённая потребность.
- **API integrations (DeepL, spell check)** — ломают strict local-first. Если делать — только opt-in per-preset + API keys в Tauri secret store + обновление threat model в CLAUDE.md (сейчас «нет доступа к сети»).
- **ACP / MCP / agent-runner внутри Rewrite** (запуск Claude Code, Codex, Gemini CLI и т.п. с UI «Agent → Action → Source → Run → diff → Apply», как в Pencil.dev / Zed). **Не сейчас** по трём причинам: (1) ломает позиционирование «prompt-first editor» в сторону «agent-in-editor» — Cursor/Zed/Continue/Aider уже занимают эту нишу, Rewrite станет bad Cursor; (2) ломает threat model «no network, no processes» — потребует Tauri permissions на сеть/процессы, провайдер-абстракцию, секретный store для ключей, diff/cancel/retry; это второй продукт внутри Rewrite размером с сам Rewrite; (3) не решает текущий реальный pain «написать ответ затратно» — это решение для другой задачи (применить AI-трансформацию к тексту), которой у пользователя нет (шаблонами в Ctrl+K не пользуется). **Условия включения:** появится конкретный кейс из реальных сессий, где «run agent inside Rewrite → diff → apply» явно выигрывает у текущего `Ctrl+Enter → Claude Code в tmux` flow. Зафиксировано как parked / future exploration, не как вечный отказ.
- **Context-mediator между tmux-агентами** (отдельный процесс/файл, собирающий контекст о проекте и инжектящий его в каждый агентский запуск). **Не сейчас:** knowledge-base direction (отказ в позиционировании), дублирует существующие `CLAUDE.md` / `AGENTS.md` (которые оба агента уже читают), требует filesystem access за пределы Rewrite. Future research note, не roadmap item.
- **rewrite-cli / rewrite-agent** — отклонены 2026-06-16 (LLM-CLI out of scope; agent-bridge без жильца; capture провалил spike). См. «Терминальные таргеты + обратная связь». Salvage `capture-as-input` — backlog-кандидат там же.

## Явные отказы

История решений «не делать», чтобы случайно не вернулись:

| Дата | Отказ | Причина |
|---|---|---|
| 2026-04-27 | `rewrite-vscode` | Противоречит концепции (Rewrite избегает code editors как UX-ответ на боль). Выпилен из экосистемы. |
| 2026-04-28 | Git-Flow (dev/release/hotfix ветки) | Overhead для solo dev на personal tool. Сам автор Git-Flow в 2020 рекомендовал GitHub Flow для CI/CD. Принят GitHub Flow: master + feature/*, --no-ff, атомарные коммиты, русские Conventional Commits. |
| 2026-04-28 | `.handoff/.decisions/.context/` dotdirs сразу | YAGNI. Один файл `HANDOFF.md` решает задачу. Split на директории — только когда HANDOFF реально перерастёт ~300 строк или появятся явно разные типы записей. |
| 2026-04-28 | Subagents для проекта | Tauri-обёртка одного SPA + редкие UX-фиксы — нет места для параллелизма. |
| 2026-04-28 | PostToolUse hook для tsc на каждый Edit/Write | Слишком медленно (5-10s на вызов). Заменено на PreToolUse(Bash:git commit) — verification только в момент коммита. |
| 2026-06-16 | `rewrite-cli` (LLM-powered text rewriter) | Out of scope: сеть/API-ключи ломают local-first. Реально shared с GUI ~10 строк (`assemblePrompt`+`PromptTemplate`) — `@rewrite/core`/монорепо преждевременны (инфра без жильцов). |
| 2026-06-16 | 2a Capture bound pane → Reference | Spike: `capture-pane` на TUI-агенте даёт весь рендер экрана, не чистый ответ; проигрывает ручному Ctrl+R; per-agent парсинг хрупкий. Herdr `pane read` не спасает (тот же TUI-рендер). Permission `capture-pane` не вводим. |
| 2026-06-16 | rewrite-agent (отдельный бинарь send/list/capture) | send/list-targets GUI делает in-process через plugin-shell; capture провалил spike. Бинарь без потребителя. |
| 2026-06-16 | Persistence diff-save | Фантом (замер в живом апе). structured-clone всех табов: 0.05мс реал / 0.1мс худший (75×10КБ); запись IndexedDB async ~5–30мс вне рендер-потока + дебаунс 500мс → jank невозможен. diff-save добавил бы dirty-tracking + bug surface ради нуля выгоды. Тот же класс, что фантом «full-text search линейный скан». |

## Open questions

Нерасковыранные грилл-ветви для будущих сессий:

- **Floating reference panel** — отдельное окно ОС vs panel в пределах главного окна. Технически разное, разный UX. Решить когда дойдёт очередь.
- **OSS-публикация механика** — какая лицензия (MIT?), формат README с дисклеймером, нужны ли скриншоты. Решить когда GUI закроет приоритеты #1–#3.

> rewrite-cli / rewrite-agent / 2a-capture ветви закрыты 2026-06-16 — см.
> «Терминальные таргеты + обратная связь» и «Явные отказы».

## Известные ограничения

- **tmux-отправка в TUI с эвристикой «вставка vs ввод» (codex и подобные)** —
  требует `paste-buffer -p` (bracketed paste) + settle-задержку перед `send-keys
  Enter`, иначе приложение глотает Enter как часть пасты и сабмит не происходит
  (первый раз проходит по гонке, повторные виснут). Исправлено в `useTmuxSend`
  (2026-06-03). Claude Code / pi.dev работали и без `-p`.

- **Bulk-replace применяет пары последовательно, не single-pass.**
  `applyReplacePairs` / `previewReplacePairs` в `replaceEngine.ts` прогоняют каждую
  пару по кумулятивному результату, поэтому цепочки вида `А→Б`, затем `Б→В`
  срабатывают каскадом (double-replacement). Для тоновых пресетов (Вы→Мы) почти не
  стреляет. «Правильный» фикс — single-pass с объединённым regex, но у пар разные
  `caseSensitive`/`wholeWord`, в один паттерн не сливаются без возни. Сознательно
  оставлено как known limitation (отмечено внешним ревью, 2026-06-14).

- **Системная тема через `gsettings color-scheme` / nwg-look** — применяется только после рестарта приложения. Это ограничение WebKitGTK на Linux, не наш баг. Смена через GTK-вариант темы (например Graphite → Graphite-Dark) работает мгновенно. Пользователь явно выбрал не реализовывать D-Bus listener (вариант 1 «оставить как есть»).
