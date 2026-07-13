# Rewrite Roadmap

> Долгоживущий документ. Источник правды по позиционированию, приоритетам и явным отказам. Обновляется по мере принятия решений в сессиях.

## Позиционирование

**Rewrite — prompt-first editor для быстрой формулировки LLM-промптов.** Возник из конкретной боли: маленький input в Claude Code + неудобный scroll в tmux при долгих сессиях.

**Не является:** pipeline-builder, knowledge base (Obsidian/Notion), code editor (VS Code/Vim).

**Целевой flow:** написал промпт в Rewrite → отправил в активную tmux pane (см. фичу #1) → продолжил в Claude Code.

## Цели проекта

> Пересмотрено 2026-07-07: курс на **staged public OSS**. См. секцию «Сессия 2026-07-07».

| Приоритет | Цель |
|---|---|
| Primary | Личный инструмент + опыт работы с Tauri/Rust |
| Primary | **Staged public OSS** — вести как настоящий открытый проект (A→B→C), честный scope |
| Secondary | Портфолио |

**Следствия (ревизия 2026-07-07):**
- 2 пользователя (автор + друг). Breaking changes без миграций всё ещё ок (ранняя стадия), но разрушающие data-изменения (IndexedDB clean sweep) координировать с другом.
- **Теперь нужны** (стадийно, для OSS): README+демо, лицензия, prebuilt release-артефакты, фикс дистрибуции (`--no-bundle` + `update.sh`), опц. CI. YAGNI-режим → нейтральный.
- **По-прежнему НЕ** без явного жильца: Windows/macOS билды, i18n, CONTRIBUTING.md, миграции данных.
- «Полировать для юзеров» vs «Tauri-эксперимент» — теперь баланс (есть внешние пользователи); polish для release-стадий оправдан, вне них Tauri-эксперимент приоритетен.

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
| 7 | Workspaces (изоляция табов по проекту; НЕ knowledge base) | [tasks/12-workspaces.md](../tasks/12-workspaces.md) | **done** (2026-07-10) — v1: изоляция TabBar + свитчер `Ctrl+Shift+W`, пины по-workspace, bulk-close скоуплен, DB v4→v5 аддитивно. Браузерные группы и сайдбар отклонены в v1 → Issues [#4](https://github.com/exviolet/rewrite-desktop/issues/4)/[#7](https://github.com/exviolet/rewrite-desktop/issues/7) |
| 8 | tmux target picker (`Ctrl+Shift+Enter` → выбор session/window/pane с именами) | [tasks/07-tmux-picker.md](../tasks/07-tmux-picker.md) | done |
| 9 | tmux tab-binding (таб → окно по `session:window` имени, цепочка Explicit→Last→Modal) | [tasks/08-tmux-tab-binding.md](../tasks/08-tmux-tab-binding.md) | done |
| 10 | Pin/unpin табов (`Ctrl+P` = pin/toggle, command palette → `Ctrl+Shift+P`) | [tasks/09-pin-unpin-tabs.md](../tasks/09-pin-unpin-tabs.md) | done |
| 11 | Reference panel → live tab (указать на живой таб вместо снапшота; замена split-view) | [tasks/10-reference-live-tab.md](../tasks/10-reference-live-tab.md) | **tab-режим отклонён (2026-07-01)** → панель репрофилируется под orca-agent-зеркало (Phase 2, см. секцию «Orca ADE») |

Файлы задач создаются в `tasks/` по мере того как фича становится active. YAGNI: не создавать stub-файлы для будущих приоритетов заранее.

### #11 reference live-tab — paused / under review (2026-06-11)

Codex реализовал tasks/10 полностью (tsc + lint exit 0), но при ревью дизайн
вызвал сомнения. **Не мержим, не выпиливаем** — код сохранён на ветке web
`feature/reference-live-tab` (коммит `70d9f6c`, не в `master`). Возврат к решению
о судьбе фичи — отложен (отдельный разговор про будущее Rewrite). README
сознательно **не** документируют live-tab, пока он не смержен.

> **2026-07-01:** судьба решена — **tab-режим отклонён.** Сомнение оказалось в
> реализации (pencil A/B-swap тихо перепривязывал панель = «непривычно») + слабый
> жилец. Панель репрофилируется: `scratch | orca-agent` (зеркало ответа Orca-агента),
> ветка `70d9f6c` — донор переиспользуемых кусков, tab-специфику (swap, D&D-таба,
> `linkedTabId`) выпилить. Это Phase 2 интеграции Orca (parked / next). См. секцию
> «Orca ADE — адопция и Rewrite↔Orca интеграция».

### Решения grill-сессии 2026-06-03 (tmux deep integration + tab UX)

- **Split-view отклонён** — дублирует существующую reference panel (`Ctrl+R`, уже side-by-side) и дрейфует в code-editor/IDE (анти-позиционирование). Заменён на #11: апгрейд reference panel до указания на живой таб.
- **tmux tab-binding (#9) биндит по имени `session:window`, НЕ по `@id`.** Window/pane `@id` эфемерны — ресетятся при рестарте tmux-сервера (ребут), поэтому persistent-привязка к `@id` протухает ровно как global-last (который сознательно НЕ персистится). Дескриптор `{session_name, window_name}` резолвится живьём в момент отправки; если окно не найдено → модалка + toast. Цена: давать агентским окнам стабильные имена (`tmux rename-window claude`).
  > **⚠️ ИСПРАВЛЕНО 2026-07-10 — это решение было НЕВЕРНЫМ и породило критический баг.** Имя окна **не уникально**: в agentic-флоу два окна `claude` — норма, а `.find(w => w.name === …)` брал первое → промпт улетал не тому агенту. Мотив («`@id` эфемерны») верен, вывод («значит биндим только по имени») — нет. **Актуально:** первичный ключ — `window_id` (`@N`), имя остаётся для отображения и как fallback. Резолв: (1) `@id` **И** имя совпали → точное попадание; (2) иначе по имени — ровно одно совпадение берём, **несколько → `ambiguous`**; (3) ноль → `not-found`. Сверка имени на шаге 1 защищает от переиспользования `@id` после рестарта сервера. **Инвариант: при неоднозначности НЕ угадывать** — переспросить (тост + bind-picker). Не откатывать к матчингу только по имени.
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

> **Обновление 2026-07-01:** herdr-кандидат **вытеснен Orca ADE** (адоптирован,
> скриптовый CLI `orca-ide`, семантический слой сессий). Orca — сильнее как «вторая
> реализация» `TerminalTarget`. Herdr не тестировался. См. секцию «Orca ADE».

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

## Сессия 2026-06-30 (trigger phrases + bound-aware switcher + WebKit fix)

Точка входа: «GUI feature-complete под позиционирование, что дальше?». Брейнсторм
6 идей → триаж → отгружено 3 вещи (все в `master` + origin). Нумерация идей ниже —
ad-hoc из этой сессии, **не** пересекается с приоритезированным roadmap выше.

**Отгружено:**

- **Trigger phrases (`Ctrl+K`)** — квик-пикер фраз-префиксов («Только план, без
  изменений:» и т.п.): выбор → префикс в начало промпта → дальше `Ctrl+Enter` в
  tmux. Фильтр/↑↓/Enter + лёгкий CRUD, 3 дефолтных фразы, иконка-молния. **Clean
  sweep:** выпилены `AIPromptPanel` / `promptBuilder` / `promptTemplatesStore`
  (clipboard-обёртка `{{TEXT}}`/`{{INSTRUCTION}}` — модель до-tmux эпохи, не
  использовалась; net −140 строк). IndexedDB v3→v4: стор `promptTemplates` удалён,
  создан `triggerPhrases` (без миграции — clean sweep, легаси-стор в upgrade через
  нетипизированный `IDBPDatabase`, иначе `tsc -b` ругается).
- **Bound-aware `Ctrl+T` switcher** — расширен существующий `TabSwitcher` (не новая
  модалка): бейдж `session:window` у привязанных табов, привязка в fuzzy-поиске
  (`work:claude`/`claude` находит), bound-табы сортируются первыми + тумблер «только
  tmux» (клавиша `Tab`). Побочно — фикс бага: `Ctrl+Backspace` больше не закрывает
  таб (был `Delete||Backspace`, перехватывал «удалить слово» в поиске), закрытие
  только `Ctrl+Del`. **fzf-лейаут пробовали и откатили** (непривычно), в master не
  попал. Stage 2 (цикл-клавиша по bound-табам) отложен — на 4–8 bound фильтр-модалка
  доминирует; добавим только если догфуд покажет, что «модалка + Tab» тяжелее.
- **WebKit DMABUF tearing fix** — см. «Известные ограничения» (последний пункт).

**Триаж идей — диспозиции:**

- **image→path в промпт (idea #1)** — **открыто, не начато.** tmux `send-keys`
  картинку не пронесёт; on-positioning вариант = «скриншот → файл → путь в промпт,
  агент читает путь». Требует Tauri **fs-write** permission + расширение threat
  model (сейчас «нет сети/процессов»). Грилл-сессия по каналу «картинка → агент» —
  предусловие.
- **CodeMirror/Lexical вместо textarea (idea #4)** — кейс **ослаблен**. «Плавный
  скролл» был главным аргументом, но оказался багом платформы (WebKit DMABUF, уже
  пофикшен без замены редактора). Остаточные плюсы (decorations вместо backdrop-хака,
  встроенный undo вместо `editorHistory.ts`) — «приятно», не «больно». Не делаем без
  сильного жильца.
- **Кастомизация (idea #5)** — **парковано.** Сегодня есть fontSize / wordWrap /
  tmuxAutoSubmit / theme; «кастомизация» слишком размыто. Предусловие: 3 конкретные
  настройки-жильца из реального потока.
- **idea #2 «отправлять только выделенное»** уже существовала (`getSendText` шлёт
  выделение если есть, иначе весь буфер); **idea #3 скролл-jank** оказалась WebKit
  DMABUF (см. выше). Строить нечего.

## Orca ADE — адопция и Rewrite↔Orca интеграция (2026-07-01)

Пользователь установил **Orca ADE** (`stablyai/orca`, MIT): agent-development
environment — параллельные CLI-агенты в изолированных git-worktree, встроенные
терминалы Ghostty-класса, семантический слой сессий агентов, скриптовый `orca-ide`
CLI. **На испытательном сроке** (плейбук herdr). Разобрали, чем Orca является для
Rewrite, и спроектировали интеграцию.

### Ключевой вывод: Orca комплементарен, НЕ заменяет Rewrite

Orca = **мультиплексор/раннер агентов** (замена tmux + herdr для агентской работы),
но **у него нет своей prompt-поверхности** — открываешь тот же Claude Code / Codex в
его тесном TUI, просто в Orca-окне. Значит боль «маленький input» (ядро Rewrite)
**остаётся**. Rewrite встаёт поверх Orca как **companion**: комфортный ввод + умная
отправка, которой у голого `orca-ide` нет. Роль заточена, вопрос «переживёт ли
Rewrite Orca» закрыт — **да, комплементарно**.

### Спайк-доказательства (живьём, `orca-ide`)

- **`terminal send` — сырой `\n` = Enter** (ранняя отправка, как tmux). Обёртка в
  bracketed-paste (`\e[200~…\e[201~`) → многострочник держится одним буфером,
  `--enter` шлёт разом. Send feasible, переиспользует bracketed-логику `useTmuxSend`.
- **`terminal read` — сырой TUI-рендер** (PUA-глифы, box-draw, спиннер, scrollback).
  Тупик для чтения ответа агента, как tmux `capture-pane` (спайк 2a).
- **`worktree ps` — СТРУКТУРНЫЙ семантический слой:** `agentType`, `state`, чистые
  `prompt` / `toolName` / **`lastAssistantMessage`** (проверено: haiku-агент отдал
  чистый текст ответа, ноль рендер-шума). **Это ОТМЕНЯЕТ вывод спайка 2a для Orca:**
  output-направление (боль B) больше не тупик — Orca сам делает per-agent парсинг.
- **`terminal wait --for tui-idle`** — работает (`satisfied: true`).

### Решения

- **Интеграция в 2 фазы:**
  - **Phase 1 — Send (боль A):** `Ctrl+Enter` → bracketed-промпт в выбранного
    Orca-агента. Без новых клавиш (дескриптор привязки получает тег `source`).
    Target-цепочка переиспользует #9 (Explicit→Active→Modal); MVP — per-tab привязка
    через picker + Explicit→Modal, «Active-agent» дефолт best-effort (гейт — семантика
    `isActive`, picker — надёжный fallback). **Orca-only MVP**, tmux-путь не трогаем.
    Спек: [tasks/11-orca-send.md](../tasks/11-orca-send.md).
  - **Phase 2 — Reference-read (боль B): parked / next.** Reference panel получает
    `orca-agent`-режим — зеркалит `lastAssistantMessage`, рефреш петлёй
    send→`wait tui-idle`→`ps`. **Не stub-им детально, пока не станет active.**
- **Permission — Policy B (scoped, НЕ `args:true`):** только `terminal send`,
  `terminal list`, `worktree ps`, `terminal wait`. Блок: `computer` (десктоп),
  `terminal create --command` (спавн процессов), `worktree create/rm`, browser,
  automations. `args:true` молча выдал бы desktop-control + произвольные процессы. См.
  CLAUDE.md Safety Rails.
- **Reference panel — tab-режим (#11) под нож.** Сомнение по #11 = «непривычная»
  реализация (pencil A/B-swap: карандаш тихо перепривязывал панель) + слабый жилец
  (кто держит требования в отдельном Rewrite-табе?). orca-agent-источник обходит оба
  (read-only внешние данные, swap не нужен). Панель = `scratch | orca-agent`,
  tab-режим (ветка web `70d9f6c`) выпилить, оставить донором переиспользуемых кусков
  (source-picker, read-only body, insert).
- **herdr вытеснен.** Orca = «herdr, но семантический + скриптовый» — это и есть та
  «вторая реализация» `TerminalTarget`, которую ждала секция «Терминальные таргеты».
  Абстракцию извлекаем из двух impl (tmux+orca) при унификации picker'а — **отложено
  до решения судьбы tmux**.
- **tmux fate — не решено** (Orca на испытательном). Унификацию picker'а не строим,
  пока не ясно, угасает ли tmux для агентов.

### Salvage: capture-as-input в Orca стал ближе

`worktree ps` — для агентов; но `terminal read` по **не-TUI** шеллу (build/test/
`git diff`/stack trace) отдаёт почти чистый текст со стабильным хендлом. Salvage-
кандидат `capture-as-input` (вытащить tool-вывод в промпт) в Orca удобнее, чем был
размытой tmux-идеей. По-прежнему backlog, нужен реальный кейс.

## Сессия 2026-07-07 — Стратегический разворот: OSS-курс, ревизия local-first, workspaces

Точка входа: разбор ночного брейндампа идей + два факта, сдвинувших рамку проекта:
**(1) у Rewrite появился 2-й пользователь** (друг автора, начал пользоваться сам, без продвижения);
**(2) автор хочет вести Rewrite как настоящий public OSS** — интересен сам опыт + вера, что нише зайдёт.

### Решение: курс на staged public OSS (адоптировано)

`Цели проекта` пересмотрены: OSS из «не цель» → **цель, стадийно, честный scope**. Обоснование:
острая недообслуженная ниша (волна agentic-coding — CC/Codex/Cursor/Aider + tmux-оркестрация: у всех
крошечный input, Rewrite — companion ко всем), доказанный dogfooding (75+ табов, 2-й юзер сам),
прямая подпитка secondary-goal (портфолио) + желаемый OSS-опыт.

**Стадии (не флипать в «полный продукт» разом):**
- **A — презентабельность:** README с GIF/asciinema send-flow, лицензия, честный scope; фикс сборки
  (`tauri build --no-bundle`, см. ниже) + `update.sh`, чтобы install работал у чужого человека.
- **B — артефакты релиза:** prebuilt бинарь/AppImage в GitHub Release (сначала починить linuxdeploy).
- **C — discoverability:** r/commandline, r/tmux, Show HN, agentic-coding комьюнити, X — под демо.

**Следствие для YAGNI:** режим сдвигается aggressive → **нейтральный** (глоб. правило: >1 юзер).
CI/README/release-артефакты/тесты перестают быть scope creep для OSS-facing инфры. Скепсис к
спекулятивным **in-app** абстракциям остаётся (1 dev). Override-файл YAGNI НЕ заводим (слишком
бинарно) — калибровка «нейтрально для дистрибуции, скептично для внутренних абстракций».

**Следствие для clean-sweep:** у друга накоплены данные → разрушающие IndexedDB-изменения (как v3→v4
clean sweep `promptTemplates`) задевают и его. Clean sweeps всё ещё ок (ранняя стадия), но
**координировать с другом** перед разрушающей data-миграцией. Полноценные миграции — по-прежнему НЕ вводим.

### Ревизия local-first (реформулировано, не отменено)

Автор оспорил local-first как догму: «мы же запускаем CC/codex — они сетевые, зачем сковывать руки?».
Разрез на две вещи под одним словом:
- **Продуктовая догма** («Rewrite никогда не в сеть/облако») — **снята.** Произвольна: Rewrite
  существует, чтобы кормить сетевые CC/codex/orca; офлайн им никто не пользуется.
- **Security-постура Tauri** («webview не делает произвольных сетевых вызовов / не спавнит процессы») —
  **сохранена, и это НЕ произвол.** У Rewrite `fs:scope-home-recursive` + write; home-read + сетевой
  egress = реальная поверхность утечки (`web/` тянется submodule'ом, не аудируется построчно). Широкий
  FS безопасен *именно потому*, что нет egress. Это в исключении «security — YAGNI отступает».

Формулировка: `local-first (догма)` → **`редактор держит границу no-network-egress; сетевое/AI живёт
в отдельном companion-продукте за узкой opt-in границей`**. Отражено в CLAUDE.md Safety Rails.

### AI-ассистент промптинга — брат-продукт (Triage, НЕ адоптировано)

Из брейндампа: «Rewrite помогает *составлять* промпты, имея контекст о проекте» (3 контекстных вопроса
как NotebookLM, memory-провайдер типа Hindsight/Hermes, RAG). Разрешение противоречия — **это другой
продукт, тесно связанный с Rewrite** (вывод самого автора), а не фича редактора.
- **Редактор-scope (можно, локально):** prompt-quality тулинг — структура/скаффолды/императивные
  чек-листы («расплывчатая фантазия → конкретное тех-требование»), продолжает `trigger phrases` (`Ctrl+K`).
- **Ассистент-scope (брат-продукт):** LLM-генерация промптов, RAG, память проекта — сеть + ключи +
  индекс = три red flag редактора (no-egress граница, не knowledge base). Отдельный companion.

**Статус: Triage.** Не проектируем, не даём течь в scope редактора. Дешёвая локальная альтернатива боли
«в длинных сессиях теряюсь / забываю решения»: локальный decisions/context-лог рядом с промптами (без
RAG/сети). Проверить, не решает ли он 80% боли, ПЕРЕД тем как строить retrieval.

### agent-hooks как back-channel — research-нота под брат-продукт (НЕ начинаем)

Наблюдение автора: Orca/herdr используют per-agent hook-скрипты (`~/.orca/agent-hooks/claude-hook.sh`,
`codex-hook.sh`, …) для прямого взаимодействия с агентами. **Ключевой инсайт:** именно так Orca получает
чистый `lastAssistantMessage`/`tui-idle` в `worktree ps` — через хуки, а не TUI-скрейп. То есть hooks —
**правильный примитив для back-channel**, в отличие от TUI-скрейпа (тупик спайков 2a/2b) и от
Orca-специфичного `worktree ps` (лок на Orca). Свои хуки дали бы orchestrator-независимый структурный
сигнал от ЛЮБОГО агента.

**Но это НЕ editor-фича, по трём причинам:**
1. **Дрейф в оркестратор.** Чтение состояния/ответов агента = слой Orca/herdr/tmux-CAO, который Rewrite
   *дополняет, не заменяет*. Подтверждено статьёй [nahornyi.ai про tmux-оркестрацию](https://nahornyi.ai/ru/news/tmux-cli-multi-agent-orchestration-pattern):
   она вся про *роутинг* агентов, но НЕ трогает *составление* промпта — вот зазор Rewrite.
2. **Новая security-поверхность = ломает границу редактора.** Хуки требуют: (a) Rewrite ПИШЕТ в конфиги
   чужих инструментов (`~/.claude/settings.json` hooks, codex-конфиг); (b) хук зовёт *обратно* → Rewrite
   ДОЛЖЕН слушать (localhost socket/pipe) = listener, ровно то, что no-egress граница исключает. → Место
   хуков — в брат-продукте (там и так сеть/ключи).
3. **Коллизия с Orca.** Когда оркестратор есть, он уже *владеет* хуками агента; Rewrite должен *потреблять
   его данные* (`worktree ps`), не ставить конкурирующие хуки. Уникальная ценность хуков — только для
   НЕ-оркестрируемого пути (голый агент в tmux).

**Диспозиция:** research-нота под брат-продукт (вероятный субстрат его read-side для любого агента).
Editor-scope применение (хук как idle/ready-сигнал для надёжности `send` вместо хрупкого settle-80ms) —
тоже требует listener → та же цена; `send` в основном работает (bracketed paste). Грилл перед стартом:
settle реально мешает в ежедневном потоке? Если нет — YAGNI. **Не начинаем.**

### Прочее из брейндампа — диспозиции

- **Workspaces (#7) — greenlit, реформулировано.** Боль «пространство»: табы проекта + личные теряются
  вместе, шум (Ctrl+T решил *переключение*, не *пространство*). Залочено как **workspace-группировка
  табов**, НЕ «хранилище/Obsidian» (knowledge-base red flag снят). **Теги для промптов — отложены** до
  доказанного жильца, которого workspace не покрывает (не строим два org-механизма разом; YAGNI).
- **Кастомизация hotkeys — кандидат.** Уточнено: именно keyboard shortcuts (remap действие→клавиша,
  персист, UI редактирования). Хорошо очерчено, помогает и другу. Спек — когда станет active.
- **Auto-scroll до активного таба** — мелкий UX-win, принят.
- **Distribution/update pain — чинить (стадия A).** Сейчас руками: `git pull` обоих репо + `bun run build`
  (падает на linuxdeploy, т.к. `bundle.targets:"all"` тянет AppImage) + `./install.sh`. Фикс: сборка для
  install через **`tauri build --no-bundle`** (бинарь есть, linuxdeploy не запускается — AppImage для
  `~/.local/bin`-инсталла не нужен) → `build && install` не рвётся. Плюс `update.sh`: pull обоих →
  `--no-bundle` build → install. Это НЕ запрещённый auto-update/CI — скрипт ручных шагов; теперь оправдан
  (OSS + 2 юзера). Для стадии B — prebuilt AppImage в Release (linuxdeploy починить там отдельно).

## Сессия 2026-07-10 — backlog переезжает в Issues, Workspaces v1, критический tmux-фикс

### Решение: backlog = GitHub Issues (адоптировано)

Претензия автора: ROADMAP превратилась в свалку — сырые идеи парковались внутри датированных
секций decision-log'а, findability нулевая. Разрез: **лог решений ценен** (аудит-трейл «почему»,
полезен и для OSS), ломало именно **смешение** сырого backlog'а с ним.

- **Backlog → GitHub Issues** в `exviolet/rewrite-desktop` (оба репо уже PUBLIC, issues включены).
  Для проекта, сознательно идущего в public OSS, трекер — не спекулятивная инфра, а table-stakes
  (как LICENSE). Живые жильцы: 2-й юзер уже завёл 2 issue сам.
- **Linear отклонён.** Приватный SaaS невидим OSS-сообществу и 2-му юзеру (backlog за логином ≠
  OSS-backlog), требует аккаунтов, тащит тяжёлую PM-машинерию (cycles/projects/статусы) под проект
  на 2 человека. Воюет с самой целью.
- **Локальный `docs/BACKLOG.md` отклонён** — при наличии Issues это был бы **второй** backlog
  (дублирование контента, тот же YAGNI-триггер).
- **Роли зафиксированы:** Issues = сырое/триаж → `docs/ROADMAP.md` = решения + обоснования →
  `tasks/NN-*.md` = активные спеки (их исполняет Codex; Issues он не читает). Созревшая issue
  переводится архитектором в спек.

Заведены #4–#8: браузерные группы, welcome/onboarding, workspace layers, конфигурируемый сайдбар,
видимость инструментов TabBar.

### Workspaces (#7) — v1 залочен

**v1 = изоляция + свитчер.** Переключение workspace **фильтрует** TabBar (видны только его табы).
Спек: [tasks/12-workspaces.md](../tasks/12-workspaces.md).

- **Изоляция ≠ группировка.** Автор предложил гибрид «изоляция + браузерные группы как в Firefox».
  Разведено: изоляция скрывает чужое (лечит названную боль «проектные + личные теряются вместе,
  шум»); браузерные группы ничего не скрывают → **ту боль не лечат**. Строить оба разом = два
  org-механизма (прямо против решения 2026-07-07). Группы → Issue #4, реанимировать если изоляция
  не закроет потребность.
- **Один workspace на таб** (партиция, не теги). **Пины — по-workspace.**
- **UI только свитчер-модалка** (`Ctrl+Shift+W`). Сайдбар с тремя режимами (постоянный/скрытый/
  hover) — не заработанный scope → Issue #7; сначала прожить со свитчером. Дропдаун в таб-баре
  отклонён (вкус автора).
- **Bulk-close скоупится workspace.** Инвариант «не разрушать молча» — «закрыть сохранённые» не
  должен трогать чужие workspace.
- **Данные аддитивны:** `Tab.workspaceId` + новый стор `workspaces` (DB v4→v5). Старые табы →
  «Default». Деструктива нет → данные 2-го юзера в безопасности.

### Критический баг tmux-привязки — исправлен

Два окна `claude` → промпт улетал не тому агенту. Решение 2026-06-03 «биндить по имени, НЕ по
`@id`» оказалось неверным (см. правку-врезку в секции grill-сессии 2026-06-03).
**Общий инвариант, вынесенный из этого:** в путях «отправить промпт агенту» при неоднозначности
**никогда не угадывать** — переспрашивать. Цена ошибки (текст ушёл чужому агенту) сильно выше
цены лишнего клика. Orca-путь этот инвариант уже соблюдал.

### Stage A OSS — барьер входа убран

`README.md`/`README.ru.md` и `.gitmodules` клонировали по SSH → посторонний без ключей не мог
собрать проект (issue #1 от 2-го юзера). Переведено на HTTPS. Локальные чекауты мейнтейнера не
затронуты (`.gitmodules` читается при свежем клоне и `submodule sync`, `update.sh` использует
`submodule update --init`).

## Отложенные идеи (не сейчас, требуют предусловий)

- **Chained Presets** + **Live Preview Transformation** — это пивот в pipeline-builder, ломает позиционирование «prompt-first editor». Включать только если появятся реально сложные пресеты и подтверждённая потребность.
- **API integrations (DeepL, spell check)** — ломают strict local-first. Если делать — только opt-in per-preset + API keys в Tauri secret store + обновление threat model в CLAUDE.md (сейчас «нет доступа к сети»).
- **ACP / MCP / agent-runner внутри Rewrite** (запуск Claude Code, Codex, Gemini CLI и т.п. с UI «Agent → Action → Source → Run → diff → Apply», как в Pencil.dev / Zed). **Не сейчас** по трём причинам: (1) ломает позиционирование «prompt-first editor» в сторону «agent-in-editor» — Cursor/Zed/Continue/Aider уже занимают эту нишу, Rewrite станет bad Cursor; (2) ломает threat model «no network, no processes» — потребует Tauri permissions на сеть/процессы, провайдер-абстракцию, секретный store для ключей, diff/cancel/retry; это второй продукт внутри Rewrite размером с сам Rewrite; (3) не решает текущий реальный pain «написать ответ затратно» — это решение для другой задачи (применить AI-трансформацию к тексту), которой у пользователя нет (prompt-шаблоны с `{{TEXT}}`-подстановкой выпилены 2026-06-30 как неиспользуемые; `Ctrl+K` теперь — trigger-phrases-пикер). **Условия включения:** появится конкретный кейс из реальных сессий, где «run agent inside Rewrite → diff → apply» явно выигрывает у текущего `Ctrl+Enter → Claude Code в tmux` flow. Зафиксировано как parked / future exploration, не как вечный отказ.
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
- **OSS-публикация механика** — курс принят 2026-07-07 (staged A→B→C, см. секцию). Осталась конкретика: лицензия (MIT?), release-механика (GitHub Release + prebuilt AppImage, починить linuxdeploy), формат README-демо (GIF/asciinema), площадки стадии C.
- **image→path вставка картинок** — открытая ветвь (idea #1 сессии 2026-06-30, см. секцию выше): «скриншот → файл → путь в промпт». Предусловие — грилл канала «картинка → агент» + threat model под Tauri fs-write.

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

- **Tearing/артефакты при скролле (WebKitGTK DMABUF-рендерер на Linux)** — на части
  GPU-драйверов (Nvidia, отдельные Mesa/Wayland) путь шаринга буферов DMA-BUF даёт
  разрывы и искажения при скролле. Не наш баг — особенность WebKitGTK. Запечено в
  `lib.rs`: на Linux выставляем `WEBKIT_DISABLE_DMABUF_RENDERER=1` до создания
  webview, если переменная не задана юзером (override сохранён). Аппаратный
  композитинг при этом остаётся. Если хирургического флага не хватает — кувалда
  `WEBKIT_DISABLE_COMPOSITING_MODE=1` (вырубает GPU-композитинг целиком). Это
  заменило ложную гипотезу «потолок textarea, нужен CodeMirror» — скролл-jank
  оказался багом платформы, а не редактора.
