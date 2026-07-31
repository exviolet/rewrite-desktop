# Task 15 — Herdr как терминальный таргет + извлечение `TerminalTarget`

**Status:** active — **фаза B done (2026-08-01, web merge `c2a134c`)**, фазы A и C впереди

> **Порядок фаз изменён по решению автора:** B (herdr) сделана **первой**, вперёд A. Причина —
> herdr нужен в бою сразу, а фаза A даёт ноль видимого выигрыша при ненулевом риске на
> daily-driver-пути отправки. Цена решения: herdr встал **третьей копией** orca-паттерна,
> которая схлопнется в фазах A/C. Реализованный herdr-путь описан ниже как есть; при
> схлопывании учесть, что он **проще** двух других (нет `--json`, нет bracketed-paste, нет
> settle) — механически подгонять его под orca-шаблон нельзя.
>
> **Закрыто живым прогоном (автор, `bun dev`):** `herdr agent prompt` **сабмитит сам** —
> отдельный Enter не нужен, `agent send-keys` в permission по-прежнему не требуется.
**Priority:** высокий — herdr стал daily driver у обоих пользователей (см. [docs/ROADMAP.md](../docs/ROADMAP.md) секция «Сессия 2026-08-01»)
**Owner:** human-planner (Claude Opus) + executor (Codex или Claude)

> Спек детальный намеренно. Где упрёшься в неясность — **проверь live-командой
> (`herdr` установлен) или оставь TODO, НЕ угадывай.** `args:true` для `herdr` —
> ЗАПРЕЩЁН категорически (см. «Permission», причина там же).

## Цель

`Ctrl+Enter` умеет отправлять промпт в **агентскую панель herdr** — третий терминальный
таргет рядом с tmux и Orca. Заодно три параллельные реализации схлопываются в
`TerminalTarget`-абстракцию, которую ROADMAP держал отложенной «до решения судьбы tmux».

**Решения автора (2026-08-01, приняты в этой сессии):**
1. **Все три таргета живут** → извлекаем `TerminalTarget`. Рабочий процесс автора:
   ≤3 проектов одновременно → herdr; >3 → Orca (Orca ест 2–3 ГБ ОЗУ уже на 2–3 агентах
   в одном проекте, herdr — нет). tmux остаётся для не-агентской работы.
2. **Таргет herdr — только агентские панели** (`herdr agent list`), не голые шеллы.
   Совпадает с orca-моделью.
3. **Один пикер с секциями** вместо трёх — та самая «унификация picker'а» из ROADMAP.

## Ключевые факты (проверены live 2026-08-01, herdr 0.7.5, protocol 17)

### Топология и семантика

- **`herdr agent list`** — вывод **уже JSON**, флага `--json` НЕТ (`herdr agent list --json`
  падает с `usage:`). Форма:
  ```json
  {"id":"cli:agent:list","result":{"type":"agent_list","agents":[{
    "pane_id":"wK:p1","tab_id":"wK:t1","workspace_id":"wK","terminal_id":"term_…",
    "agent":"claude","agent_status":"working","cwd":"/home/…/rewrite-desktop",
    "focused":true,"terminal_title_stripped":"…"}]}}
  ```
  Один вызов даёт всё: и семантику агента, и хендл. Джоин двух команд (как в Orca) **не нужен**.
- **`agent_status`** ∈ `idle | working | blocked | done | unknown`.
- Человекочитаемых лейблов в `agent list` НЕТ — только id. Лейблы берутся из
  **`herdr workspace list`** (`{workspace_id, label, focused, …}`) и
  **`herdr tab list`** (`{tab_id, workspace_id, label, number, …}`). Оба тоже отдают
  голый JSON без флага.
- `terminal_title_stripped` — заголовок TUI (у Claude Code это **текущая задача**,
  меняется каждую минуту). **Для лейбла в пикере не использовать**, только как
  вторичную подсказку.

### Таргет и стабильность (критично)

- Таргет всех `agent`-команд — **`pane_id`** вида `wK:p1`. Формы `term_…`, `wK:t1`,
  имя агента, `focused` — **не принимаются** (`agent_not_found`, проверено перебором).
- **`pane_id` персистится** в `~/.config/herdr/session.json`: `workspaces[].id` = `wK`,
  `public_pane_numbers` = map «внутренний id → публичный номер». То есть в отличие от
  tmux `@id` и orca `term_…` привязка **переживает рестарт сервера и ребут**.
- **НО номера переиспользуются** (`next_public_pane_number` + освобождение при закрытии
  панели). Это ровно та поверхность, на которой родился баг 2026-07-10. Следствие ниже
  в «Решениях» — не ослаблять.
- Лейблы **не уникальны**: у автора прямо сейчас две вкладки `codex` в одном workspace.

### Отправка

- **`herdr agent prompt <pane_id> <text> [--wait] [--until STATUS]... [--timeout MS]`** —
  first-class отправка промпта. Ответ: `{"result":{"type":"agent_prompted","agent":{…}}}`.
  Bracketed-paste руками оборачивать **не нужно**, settle-таймер тоже — герой делает это сам.
- **`herdr pane send-text <pane_id> <text>`** — литеральный ввод **без** Enter.
- ⚠️ **ЕДИНСТВЕННОЕ НЕПРОВЕРЕННОЕ:** сабмитит ли `agent prompt` сам (жмёт Enter).
  Косвенно — да: имя результата `agent_prompted`, наличие `--wait --until idle`,
  отсутствие флага «не сабмитить». **Проверить первой же live-командой на скретч-панели
  ПЕРЕД написанием `send()`.** Если сабмитит — маппинг в «Решениях» верен; если нет —
  добавить `agent send-keys <pane> Enter` и внести в permission (в спеке НЕ разрешена).

### Чего у herdr НЕТ

`AgentInfo` **не содержит** аналога orca-шного `lastAssistantMessage` — чистого ответа
агента. Есть только `agent read`, а это тот же отрендеренный TUI, который провалил
спайк 2a (2026-06-16). **Следствие: read-сторона (боль B, зеркало ответа в reference-
панели) остаётся orca-only.** В этом таске read не трогаем вообще.

## Решения (архитектура)

### Модель привязки — одно поле вместо трёх

`Tab.tmuxBinding` + `Tab.orcaBinding` схлопываются в **`Tab.binding?: TabBinding`** —
дискриминированное объединение по `source`:

```ts
export type TargetSource = "tmux" | "orca" | "herdr";

export type TabBinding =
  | { source: "tmux";  session: string; window: string; windowId?: string }
  | { source: "orca";  worktree: string; titleHint?: string }
  | { source: "herdr"; paneId: string; workspace: string; tab: string };
```

`workspace`/`tab` у herdr — это **лейблы** (`rewrite-desktop`, `1`), а не id: id-шники
(`wK`) внутренние и пересобираются, лейблы человекочитаемы и попадают в бейдж таба.

**Старые привязки не теряем.** `normalizeTab` (`lib/tabUtils.ts`) при чтении
конвертирует легаси-поля в новое:
```ts
// migration-shim'ов не заводим: это нормализация на чтении, там же где titleSource
const binding = tab.binding
  ?? (tab.tmuxBinding ? { source: "tmux", ...tab.tmuxBinding } : undefined)
  ?? (tab.orcaBinding ? { source: "orca", ...tab.orcaBinding } : undefined);
```
Легаси-поля после конверсии **не пишем обратно** (не сериализуем). Это не «миграция
данных» в смысле Safety Rails — bump версии БД не нужен, схема стора табов не меняется.
У автора 4 живых tmux-привязки, у друга — свои; терять их нельзя.

### `TerminalTarget` — форма абстракции

Новый каталог `web/src/lib/terminalTargets/`:

```ts
export interface TerminalTarget {          // строка в пикере
  source: TargetSource;
  key: string;                             // уникальный ключ строки (source + handle)
  handle: string;                          // что уедет в send()
  binding: TabBinding;                     // что сохранится в таб при bind
  primary: string;                         // "claude · rewrite-desktop / 1"
  secondary?: string;                      // cwd или превью промпта
  status?: string;                         // agent_status / state — бейдж
  isActive?: boolean;                      // focused — для преселекта
}

export type Resolution =
  | { kind: "ok"; handle: string }
  | { kind: "not-found" }
  | { kind: "ambiguous"; count: number };

export interface TerminalProvider {
  source: TargetSource;
  label: string;                           // заголовок секции пикера: "Herdr"
  isAvailable(): Promise<boolean>;         // бинарь есть и отвечает
  listTargets(): Promise<TerminalTarget[]>;
  resolve(binding: TabBinding): Promise<Resolution>;
  send(handle: string, text: string, submit: boolean): Promise<void>;
  describe(binding: TabBinding): string;   // бейдж в TabBar / StatusBar / TabSwitcher
}
```

Реестр — `terminalTargets/index.ts`: `providers: Record<TargetSource, TerminalProvider>`
+ `providerFor(binding)`. Порядок секций в пикере фиксированный: **herdr → orca → tmux**
(частота использования).

**`Resolution` возвращает `ambiguous` явно, а не `null`.** Сегодняшние
`resolveOrcaBinding`/`resolveTmuxBinding` схлопывают «не нашли» и «несколько» в один
исход — инвариант «не угадывать» соблюдается, но пользователю нельзя показать
**почему** открылся пикер. Развести: тост «панель пропала» vs «совпадений несколько —
привяжи заново».

### Провайдер herdr

- `isAvailable()` — `herdr agent list` вернул exit 0 и парсится. Сервер не запущен →
  `false` → **секция herdr в пикере не рисуется вовсе** (не пустая секция, не ошибка).
  То же правило применить к orca — сегодня orca-пикер показывает error-state.
- `listTargets()` — три команды **параллельно** (`Promise.all`): `agent list`,
  `workspace list`, `tab list`. Джоин по `workspace_id` / `tab_id` → лейблы.
  `primary` = `` `${agent} · ${wsLabel} / ${tabLabel}` ``, `secondary` = `cwd`,
  `status` = `agent_status`, `isActive` = `focused`, `handle` = `pane_id`.
  Агенты с `agent_status: "unknown"` и без поля `agent` **отфильтровать** — это панели
  без распознанного агента (решение 2 автора).
- `resolve(binding)` — **двухступенчато, как в `tmuxResolve.ts`:**
  1. Совпал `pane_id` **И** оба лейбла (`workspace`, `tab`) → `ok`. Сверка лейблов —
     защита от **переиспользованного номера панели**: без неё промпт уедет в чужого
     агента ровно как в баге 2026-07-10.
  2. Иначе — матч по паре лейблов: ровно одно совпадение → `ok` (панель пересоздали,
     номер сменился — привязка самочинится); ≥2 → `ambiguous`; 0 → `not-found`.
  **Никогда не брать первое совпадение.**
- `send(handle, text, submit)`:
  - `submit === true` → `herdr agent prompt <handle> <text>`;
  - `submit === false` → `herdr pane send-text <handle> <text>`.
  Настройка `settings.tmuxAutoSubmit` переиспользуется как есть (переименовать в
  `autoSubmit` — **опционально**, только если не тянет за собой ключ в IndexedDB).
  Bracketed-paste и settle-таймер для herdr **НЕ применять** — CLI делает это сам,
  ручная обёртка `\x1b[200~` уедет в промпт литералом.
  `--wait` не используем (блокирующий вызов в UI-потоке ради ничего).
- `describe(binding)` → `` `${binding.workspace}/${binding.tab}` ``.

### Единый пикер

`TmuxTargetPicker` (214 строк) + `OrcaTargetPicker` (150) → один
`components/TargetPicker/TargetPicker.tsx` на `usePickerModal`, секции по провайдерам,
**плоский курсор сквозь секции через `data-picker-index`** — ровно как в
`GlobalSearchPanel` (образец из #9, фаза B2). Режимы `send | bind` сохраняются.

- Загрузка: `Promise.allSettled` по провайдерам, чей `isAvailable()` истинен. Упавший
  провайдер — секция не рисуется, ошибка в тост, **остальные работают** (herdr не должен
  падать из-за мёртвой Orca).
- Преселект: сначала `isActive`-таргет провайдера текущей привязки, иначе первый.
- Фильтр: по `primary` + `secondary` + имени источника, чтобы `herdr` в строке поиска
  сужал до секции.

`Ctrl+Shift+Enter` открывает его в режиме `send`. `Ctrl+Alt+B` / `Ctrl+Alt+Shift+B`
становятся source-agnostic (привязать/отвязать активный таб).

### Диспетчер `Ctrl+Enter`

`App.tsx`: `tab.binding` → `providerFor(binding)` → `resolve` → `send`.
Цепочка: **Explicit** (привязка таба) → **Last** (последний выбор, in-memory,
теперь `{ source, handle }`) → **Modal** (единый пикер). tmux-специфичный
`tmuxStore` переименовать/обобщить в `lastTargetStore` — по-прежнему **не персистится**.

## Фазы

Три независимо отгружаемых и обкатываемых куска. Каждая фаза — свой коммит; мержить
в `master` можно после любой.

- **Фаза A — абстракция без новой функциональности.** `terminalTargets/` (типы, реестр,
  провайдеры tmux и orca), `Tab.binding` + `normalizeTab`, `tabsMetaEqual`, диспетчер.
  Пикеры и хоткеи **не трогаем** — два старых пикера остаются, просто зовут провайдеров.
  Внешнее поведение не меняется ни в одном пункте. ⚠️ Это фаза с нулевым видимым
  выигрышем и ненулевым риском на daily-driver-пути отправки — **обкатать перед B**.
- **Фаза B — провайдер herdr + permission.** Секция herdr появляется в существующем
  orca-пикере (переименованном), привязка/отправка работают. Фича становится полезной.
- **Фаза C — единый пикер.** Схлопнуть два пикера в один, обобщить хоткеи, StatusBar/
  TabBar/TabSwitcher-бейджи на `describe()`.

## Permission — `src-tauri/capabilities/default.json`

> ⛔ **`args:true` для `herdr` запрещён и это не формальность.** В том же бинаре живут
> `pane run` (запуск произвольного процесса), `pane split/close/move/swap`,
> `tab create/close`, `workspace create/close`, `session stop/delete`, `server stop`,
> `config *`, `update`, `integration install/uninstall`, `notification show`,
> `agent start`. `args:true` выдал бы webview всё это разом — качественно хуже, чем
> tmux-овский `args:true`, и ровно та причина, по которой `orca-ide` заскоуплен Policy B.
> Не ослаблять; при затыке — TODO.

Добавить в `shell:allow-execute.allow` (`{v:"…"}` = `{"validator":"…"}`):

```
{ "name": "herdr-agent-list",     "cmd": "herdr", "args": ["agent", "list"] }
{ "name": "herdr-workspace-list", "cmd": "herdr", "args": ["workspace", "list"] }
{ "name": "herdr-tab-list",       "cmd": "herdr", "args": ["tab", "list"] }
{ "name": "herdr-agent-prompt",   "cmd": "herdr",
  "args": ["agent", "prompt", {v:"^w[A-Za-z0-9]+:p[A-Za-z0-9]+$"}, {v:"^[\\s\\S]*$"}] }
{ "name": "herdr-pane-send-text", "cmd": "herdr",
  "args": ["pane", "send-text", {v:"^w[A-Za-z0-9]+:p[A-Za-z0-9]+$"}, {v:"^[\\s\\S]*$"}] }
```

Валидатор `pane_id` привязан к реальной форме (`wK:p1`, `wH:pA` — суффикс буквенно-
цифровой, не только цифры). Бинарь резолвится по PATH (`/usr/sbin/herdr` → `/usr/bin/herdr`,
`/usr/sbin` — симлинк на `bin`), как `tmux` и `orca-ide`.

**Явно НЕ добавлять:** `pane run`, `pane split/close/move/swap/zoom/resize/focus`,
`pane read`, `agent read`, `agent start`, `agent send-keys`, `agent focus`,
`tab *`(кроме `list`), `workspace *`(кроме `list`), `session *`, `server *`, `config *`,
`channel *`, `update`, `integration *`, `notification *`, `worktree *`, `api *`.

## Acceptance criteria

- [ ] `lib/terminalTargets/{types,index,tmux,orca,herdr}.ts` — реестр + три провайдера.
      Чистая логика резолва (без Tauri) вынесена отдельно и проверяема, как `tmuxResolve.ts`.
- [ ] `Tab.binding?: TabBinding` в `editorStore`; `setTabBinding(id, binding | null)` —
      один экшен вместо двух. Легаси `tmuxBinding`/`orcaBinding` читаются
      `normalizeTab`, **старые привязки автора и друга целы после апгрейда**.
- [ ] `tabsMetaEqual` (`TabBar.tsx:28`) сравнивает `binding` (source + все поля), а не
      два старых объекта. Без этого полоса замерзает — **четвёртый** случай того же
      класса после `orcaBinding`, `workspaceId`, `groupId`.
- [ ] herdr-провайдер: `agent list` + `workspace list` + `tab list` параллельно, джоин
      по id, фильтр не-агентских панелей.
- [ ] Резолв herdr: `pane_id` **и** оба лейбла → `ok`; иначе по лейблам ровно одно →
      `ok`; ≥2 → `ambiguous` (тост + пикер, **не отправлять**); 0 → `not-found`.
- [ ] Отправка: `submit` → `agent prompt`; `!submit` → `pane send-text`. Bracketed-paste
      и settle **не применяются** к herdr.
- [ ] Недоступный провайдер (сервер не запущен / бинаря нет) → секции нет, остальные живы.
- [ ] Единый `TargetPicker` с секциями, плоский курсор через `data-picker-index`,
      режимы `send | bind`. Два старых пикера удалены.
- [ ] `Ctrl+Enter` / `Ctrl+Shift+Enter` / `Ctrl+Alt+B` / `Ctrl+Alt+Shift+B` —
      source-agnostic. Команды палитры `orca-bind`/`orca-unbind`/tmux-аналоги схлопнуты
      в одну пару.
- [ ] Бейдж привязки (TabBar, StatusBar, `Ctrl+T`) рисуется через `describe()`, показывает
      источник.
- [ ] `capabilities/default.json` — 5 скоупленных entries, `args:true` нет.
      `bun run build` проходит (валидация манифеста).
- [ ] `!isTauri` — clipboard-фолбэк, как сейчас.
- [ ] `cd web && bun tsc -b && bun lint` — 0 (гейт `-b`, НЕ `--noEmit`).

## Test plan (manual, в живом herdr)

0. **ПЕРВЫМ ДЕЛОМ:** на скретч-панели проверить, сабмитит ли `herdr agent prompt` сам
   (см. «Ключевые факты»). От ответа зависит `send()`.
1. Привязать таб к агенту herdr через пикер → бейдж появился, источник виден.
2. Многострочный промпт + `Ctrl+Enter` → в TUI агента прилетел **весь блок одним
   куском**, сабмит ровно один. Сравнить с tmux/orca — регрессии там нет.
3. Выделить кусок → `Ctrl+Enter` → ушло только выделенное (`getSendText`).
4. `autoSubmit = off` → текст введён, Enter не нажат.
5. **Переиспользование номера:** закрыть привязанную панель, создать новую (получит тот
   же `pane_id`), `Ctrl+Enter` → лейблы не совпали → **пикер, а не отправка чужому агенту**.
6. **Неоднозначность:** две вкладки с одинаковым лейблом (у автора уже есть две `codex`),
   привязка с протухшим `pane_id` → тост «совпадений несколько», пикер, отправки нет.
7. Панель пересоздана, лейблы уникальны → привязка самочинится, отправка проходит.
8. Рестарт herdr-сервера → `pane_id` тот же → привязка пережила (то, чего не умеют
   ни tmux, ни orca).
9. Остановить herdr-сервер → секция herdr исчезла, tmux/orca работают.
10. Перезапуск Rewrite → привязка восстановлена. **Легаси:** таб со старой
    `tmuxBinding`/`orcaBinding` открылся с рабочей привязкой.
11. Полоса табов реактивна при смене привязки (проверка `tabsMetaEqual`).
12. `bun tsc -b` + `bun lint` + `bun run build` = 0.

## Явные отказы

- **НЕ `args:true`** для `herdr` (см. врезку в Permission).
- **НЕ read-сторона.** `agent read` — тот же TUI-рендер, что провалил спайк 2a; чистого
  `lastAssistantMessage` у herdr нет. Зеркало ответа остаётся orca-only.
- **НЕ голые шеллы как таргет** (решение 2 автора) — только панели с распознанным агентом.
- **НЕ `agent start`, `pane run`, `tab create`** — Rewrite не спавнит агентов и процессы.
- **НЕ `--wait`/`agent wait`** в UI-потоке.
- **НЕ bracketed-paste/settle для herdr** — CLI делает сам, ручная обёртка утечёт в промпт.
- **НЕ bump версии БД** — схема стора табов не меняется, `binding` аддитивен, легаси
  читается нормализацией.
- **НЕ трогать tmux- и orca-поведение** сверх переезда на провайдеры.

## Definition of done

- Acceptance criteria checked, test plan пройден в живом herdr.
- `cd web && bun tsc -b && bun lint` clean; `bun run build` ок (манифест).
- Ветка `feature/herdr-target` внутри `web/`, русские Conventional Commits, мерж `--no-ff`.
- Desktop: коммит `capabilities/default.json` + бамп указателя submodule.
  **Порядок: web push → desktop bump** (Safety Rail).
- Оба README (EN+RU) и `web/CLAUDE.md` дополнены herdr-таргетом.
- Друга предупредить: привязки переехали в одно поле (данные целы), появился третий
  таргет.
