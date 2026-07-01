# Task 11 — Orca send (Phase 1: Rewrite → Orca-агент)

**Status:** active (spec ready)
**Priority:** Orca-интеграция Phase 1 (см. [docs/ROADMAP.md](../docs/ROADMAP.md) секция «Orca ADE»)
**Owner:** human-planner (Claude Opus) + executor (**Codex**)

> Спек детальный намеренно: исполнитель — Codex. Где упрёшься в неясность (особенно
> точная форма `--json`-вывода `orca-ide`) — **проверь live-командой или оставь
> TODO-комментарий, НЕ угадывай.** `args:true` в манифесте — ЗАПРЕЩЁН (см. «Явные
> отказы»), при затыке со скоупом оставляй TODO, не ослабляй.

## Цель

`Ctrl+Enter` умеет отправлять промпт не только в tmux-pane, но и в **терминал
Orca-агента** (Orca ADE, CLI `orca-ide`). Боль: у Orca нет своей prompt-поверхности —
агент живёт в тесном TUI; Rewrite даёт комфортный ввод + умную многострочную отправку.

**Только send (Phase 1).** Чтение ответа агента (reference panel `orca-agent`-режим) —
Phase 2, НЕ в этом таске.

## Ключевые факты (проверены спайком 2026-07-01)

- `orca-ide terminal send --terminal <h> --text <t>` шлёт `\n` **сырым = Enter** →
  многострочник сабмитится построчно (как tmux без bracketed paste). **Фикс:**
  обернуть payload в bracketed-paste маркеры `ESC[200~ … ESC[201~` (`\x1b[200~`/
  `\x1b[201~`) — тогда TUI держит весь блок одним буфером, отдельный `--enter` шлёт
  разом. Это аналог tmux `paste-buffer -p`.
- `orca-ide worktree ps --json` → `result.worktrees[].agents[]` с полями `agentType`,
  `state`, `prompt`, `paneKey`, `lastAssistantMessage`. Worktree имеет `path`,
  `displayName`, `isActive`.
- `orca-ide terminal list --json` → живые терминалы с `handle` (`term_…`), worktree,
  `tabId`, `title`. Хендл эфемерен — НЕ персистить; резолвить живьём.
- `agents[].paneKey` = `"<tabId>:<leafId>"` → джоинится с терминалом по `tabId`
  (первая часть до `:`). **Проверь точные имена полей в реальном `--json`** — форму
  `terminal list --json` я не фиксировал, инспектируй.

## Решения (архитектура)

- **Отдельный Orca-путь, зеркало tmux-модулей. НЕ унифицировать с tmux.** tmux-fate не
  решён → строим Orca-only, tmux-путь не трогаем (кроме взаимного сброса привязки).
  Единый picker (TerminalTarget-абстракция) — отложен до решения судьбы tmux.
- **Привязка на табе, отдельным полем `orcaBinding`** (параллельно `tmuxBinding`).
  Дескриптор `{ worktree: string; titleHint?: string }` — стабильные значения, резолв
  хендла живьём. Взаимоисключимость: привязка к Orca сбрасывает `tmuxBinding` и наоборот
  (один таргет на таб).
- **Триггер — без новых клавиш.** `Ctrl+Enter` становится диспетчером: если у активного
  таба есть `orcaBinding` → Orca-send; иначе — существующий tmux-flow (не трогаем).
- **Цепочка резолва (MVP): Explicit → Modal.** Есть `orcaBinding` → резолв → send;
  не резолвится (агент пропал / ≥2 совпадения) → open Orca-picker. «Active-agent»
  zero-config дефолт (без привязки) — **НЕ в этом MVP** (гейт — семантика `isActive`).
- **Settle как в tmux:** между bracketed-send и `--enter` — `setTimeout 80ms` (не
  `terminal wait`; wait — Phase 2).

## Acceptance criteria

- [ ] `capabilities/default.json`: `orca-ide` заскоуплен **Policy B** — 4 подкоманды
      (`terminal send`, `terminal list`, `worktree ps`, `terminal wait`) через
      per-подкоманду allow-entries с arg-валидаторами. НЕ `args:true`. `bun run build`
      проходит (валидация манифеста).
- [ ] `editorStore`: `OrcaBinding { worktree: string; titleHint?: string }`,
      поле `tab.orcaBinding?`, экшен `setOrcaBinding(id, binding | null)`. Установка
      Orca-привязки сбрасывает `tmuxBinding`; `setTabBinding` (tmux) сбрасывает
      `orcaBinding`. Персист — как у `tmuxBinding` (табы уже персистятся, отдельного
      db-поля не нужно; проверь, что `orcaBinding` попадает в сериализацию таба).
- [ ] `useOrcaSend.ts` (зеркало `useTmuxSend.ts`): `runOrca(args)`,
      `listOrcaAgentTargets()`, `resolveOrcaBinding(binding)`, `useOrcaSend()`.
- [ ] Bracketed-отправка: `--text` payload = `\x1b[200~` + text + `\x1b[201~`; при
      submit — settle 80ms + отдельный `terminal send --enter`.
- [ ] `useOrcaActions.ts` (зеркало `useTmuxActions.ts`): `handleOrcaSend`,
      `handleOrcaPick`, `bindActiveTabOrca`, `unbindActiveTabOrca`, `orcaPicker` state.
- [ ] Диспетчер `Ctrl+Enter`: `orcaBinding` → `handleOrcaSend`, иначе `handleTmuxSend`.
- [ ] `OrcaTargetPicker.tsx` (зеркало `TmuxTargetPicker.tsx`): список агентов из
      `worktree ps`, группировка по worktree, бейджи `agentType`/`state` + превью
      `prompt`. Режимы `send` | `bind`.
- [ ] Command palette: `orca-bind` / `orca-unbind` (без нового глобального шортката в
      MVP — избегаем конфликтов; шорткат — опционально/TODO). Метка tmux-команды
      `Ctrl+Enter` → «Отправить (tmux/Orca)».
- [ ] Индикатор привязки: в `StatusBar` / `TabBar` показывать orca-привязку рядом с
      tmux-индикатором (иконка + `worktree·title`), как сделано для `tmuxBinding`.
- [ ] Web-платформа без Tauri (`!isTauri`): Orca недоступен → тост/копипаст-фолбэк
      (как tmux fallback в `useTmuxSend`).
- [ ] `cd web && bun tsc -b && bun lint` — clean (гейт типов — `-b`, НЕ `--noEmit`).

## Scope (реализация)

### Permission — `src-tauri/capabilities/default.json`

Добавить в `shell:allow-execute.allow` (рядом с `tmux`) **скоупленные** entries. Форма
allow-entry: `{ "name": ..., "cmd": "orca-ide", "args": [<строка | {"validator":"<regex>"}> ...] }`.
Rewrite шлёт РОВНО фиксированные формы ниже (всегда `--json`, фиксированный порядок) —
чтобы валидаторы совпадали:

- **send text:** `["terminal","send","--terminal",{v:"term_[0-9a-fA-F-]+"},"--text",{v:"[\\s\\S]*"},"--json"]`
- **send enter:** `["terminal","send","--terminal",{v:"term_[0-9a-fA-F-]+"},"--enter","--json"]`
- **worktree ps:** `["worktree","ps","--json"]`
- **terminal list:** `["terminal","list","--json"]`
- **terminal wait** (для Phase 2, permission заранее): `["terminal","wait","--terminal",{v:"term_[0-9a-fA-F-]+"},"--for","tui-idle","--timeout-ms",{v:"[0-9]+"},"--json"]`

(`{v:"…"}` = `{"validator":"…"}`.) **НЕ добавлять** `terminal create/close/read/…`,
`computer`, `worktree create/rm`, `tab`/browser, `automations`. Если tauri-plugin-shell
не выражает какую-то форму чисто — TODO, НЕ `args:true`.

### `web/src/hooks/useOrcaSend.ts` (новый; зеркало `useTmuxSend.ts`)

- `runOrca(args: string[])`: `Command.create("orca-ide", args).execute()`, throw при `code !== 0` (как `runTmux`).
- Типы: `OrcaAgentTarget { handle; worktreePath; displayName; title; agentType; state; promptPreview; isActive }`.
- `listOrcaAgentTargets(): Promise<OrcaAgentTarget[]>`:
  1. `worktree ps --json` → собрать агентов (worktree path/displayName/isActive + agent agentType/state/prompt/paneKey).
  2. `terminal list --json` → маппинг `tabId → handle/title`.
  3. Джоин: `paneKey.split(":")[0] === terminal.tabId` → прикрепить `handle`/`title`.
  → отфильтровать только worktree с агентами. **Проверь точные поля `terminal list --json`.**
- `resolveOrcaBinding(binding: OrcaBinding): Promise<string | null>`: `listOrcaAgentTargets()`,
  фильтр по `worktree` (совпадение `worktreePath` ИЛИ `displayName`) [+ `titleHint` если задан].
  Ровно 1 → его `handle`. 0 или ≥2 → `null` (→ вызывающий откроет picker). try/catch → null.
- `useOrcaSend()`: `useCallback(async (text, opts: { target: { handle: string }; submit: boolean }) => {…})`:
  - пусто/`!isTauri` — как в `useTmuxSend` (тост / clipboard-фолбэк).
  - `const wrapped = "\x1b[200~" + text + "\x1b[201~";`
  - `await runOrca(["terminal","send","--terminal",handle,"--text",wrapped,"--json"]);`
  - `if (opts.submit) { await sleep(80); await runOrca(["terminal","send","--terminal",handle,"--enter","--json"]); }`
  - тост успех/ошибка (как tmux).

### `web/src/hooks/useOrcaActions.ts` (новый; зеркало `useTmuxActions.ts`)

- `orcaPicker` state: `null | { mode: "send" } | { mode: "bind"; tabId }`.
- `handleOrcaSend`: `getSendText()` (переиспользовать существующий из useTmuxActions —
  вынести в общий util `getSendText(textareaRef)` ИЛИ продублировать; выбрать меньшее
  зло, обосновать комментом). Взять `activeTab.orcaBinding` → `resolveOrcaBinding` →
  есть handle: send с `submit = tmuxAutoSubmit` (переиспользуем настройку); нет →
  тост + `setOrcaPicker({ mode: "send" })`.
- `handleOrcaPick(target)`: mode `bind` → `setOrcaBinding(tabId, { worktree: target.worktreePath, titleHint: target.title })` + тост; mode `send` → send в `target.handle`.
- `bindActiveTabOrca` / `unbindActiveTabOrca`: как tmux-аналоги.

### Диспетчер — `web/src/App.tsx` + `web/src/hooks/useCommands.ts`

- В App.tsx подключить `useOrcaActions(textareaRef)`; собрать `handleSend = () =>
  useEditorStore.getState().tabs.find(active)?.orcaBinding ? handleOrcaSend() : handleTmuxSend()`.
- Команду `tmux-send` (`Ctrl+Enter`) перенавесить на `handleSend`, метка «Отправить (tmux/Orca)».
- Добавить команды `orca-bind` / `orca-unbind` в `useCommands` (без глобального шортката).
- Отрендерить `<OrcaTargetPicker>` (по образцу того, как рендерится `TmuxTargetPicker` в App.tsx).

### `web/src/components/OrcaPicker/OrcaTargetPicker.tsx` (новый; зеркало `TmuxTargetPicker.tsx`)

- Пропсы `{ onPick, onClose, mode }`. При открытии — `listOrcaAgentTargets()`, лоадер/ошибка.
- Список группами по worktree (`displayName`), строка агента: бейдж `agentType`, точка
  `state`, `title`, обрезанный `promptPreview`. Клик → `onPick(target)`. Фильтр по вводу
  (как tmux picker). Escape/клик-вне — закрытие.

### Индикаторы — `StatusBar.tsx`, `TabBar.tsx`

- Показать `tab.orcaBinding` рядом с `tmuxBinding` (иконка + `displayName·title`,
  `title=…`). Не дублировать оба одновременно (взаимоисключимы). В `TabBar` кастомную
  equality-функцию (стр. ~30) дополнить сравнением `orcaBinding` — иначе индикатор
  замёрзнет.

## Test plan (manual, в Orca live)

1. В Orca открыть worktree с запущенным агентом (Claude Code/codex).
2. Rewrite: command palette → `orca-bind` → picker показывает агента с agentType/state →
   выбрать. Индикатор привязки появился на табе.
3. Написать многострочный промпт, `Ctrl+Enter` → в TUI агента прилетел **весь блок
   одним куском** (не построчно), submit сработал один раз. (codex — если submit не
   срабатывает, проверить settle; см. «Известные ограничения» tmux.)
4. Выделить кусок → `Ctrl+Enter` → ушло только выделенное (`getSendText`).
5. Закрыть агента в Orca → `Ctrl+Enter` → тост «не найден» + picker.
6. `orca-unbind` → таб снова шлёт в tmux (если был tmux-fallback) или в никуда → picker.
7. Привязать таб к tmux → `orcaBinding` сброшен, и наоборот.
8. Перезапуск Rewrite → `orcaBinding` восстановлен.
9. Verification: `cd web && bun tsc -b && bun lint` clean; `bun run build` (манифест) ок.

## Явные отказы

- **НЕ `args:true`** для `orca-ide` — только 4 скоупленных подкоманды (Policy B). При
  затыке — TODO, не ослаблять (Safety Rail, требует переподтверждения).
- **НЕ унифицировать** tmux+orca picker / не вводить общий `TerminalTarget` сейчас
  (tmux-fate не решён). Два параллельных пути.
- **НЕ чтение ответа агента** (`worktree ps` `lastAssistantMessage` в UI) — это Phase 2.
- **НЕ «Active-agent» zero-config send** без привязки — MVP только Explicit→Modal.
- **НЕ `terminal wait`** в коде Phase 1 (settle таймером, как tmux); permission на wait
  выдан заранее под Phase 2.
- НЕ трогать существующий tmux-flow, кроме взаимного сброса привязки + переименования
  метки команды.
- НЕ вводить schema-миграции.

## Definition of done

- Acceptance criteria checked.
- `cd web && bun tsc -b && bun lint` clean; `bun run build` ок (манифест).
- Manual test plan пройден в живой Orca.
- Web-коммит на ветке `feature/orca-send` (внутри `web/`: `cd web && git switch -c
  feature/orca-send`), русский Conventional Commit. Desktop: отдельный коммит
  `capabilities/default.json` + bump указателя submodule (порядок: web push → desktop bump).
