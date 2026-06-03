# Task 08 — tmux tab-binding + resolution chain

**Status:** active
**Priority:** #9 (см. [docs/ROADMAP.md](../docs/ROADMAP.md))
**Owner:** human-planner (Claude Opus) + executor (Claude Code)

## Цель

Фаза B поверх picker'а (#8). Привязать таб к конкретному tmux-окну по имени,
чтобы `Ctrl+Enter` слал промпт строго своему агенту независимо от того, какая
pane сейчас активна. Решает сценарий «таб Refactoring → Claude, таб Tests →
Codex».

## Решения (зафиксированы в grill-сессии 2026-06-03)

- **Binding по имени** `{ session, window }`, НЕ по эфемерному `@id`. Резолв
  живьём при каждой отправке.
- **Цепочка резолва `Ctrl+Enter`:**
  1. **Explicit** — у таба есть `tmuxBinding` → резолвим окно по имени → активная
     pane окна. Окно не найдено → toast + открыть picker.
  2. **Last** — привязки нет → последний выбранный в picker'е таргет (in-memory).
  3. **Fallback** — ни привязки, ни last → открыть picker.
- `Ctrl+Shift+Enter` — всегда picker (принудительный выбор).
- «Active pane» больше НЕ тихий дефолт — остаётся пунктом внутри picker'а.
- **Persistence:** `tmuxBinding` — поле на `Tab` → авто-персист в IndexedDB и
  авто-очистка при закрытии таба. `lastTarget` — in-memory (`tmuxStore`, уже есть).
- **Settings hardcode:** `remember last globally` = on, `auto-bind on pick` = off.
  Тумблеры в Settings-UI НЕ выносим (YAGNI — пока поведение дефолтное).
- **Clean sweep:** старые `tmuxTargetMode` / `tmuxTargetPane` (ручной pane id)
  удаляются — цепочка их замещает. `tmuxAutoSubmit` остаётся.

## Acceptance criteria

- [ ] У `Tab` есть опциональное `tmuxBinding: { session, window }`; экшен
      `setTabBinding(id, binding | null)`.
- [ ] Контекстное меню таба: «Привязать к tmux-окну…» открывает picker в
      bind-режиме; на выбор — таб привязывается (не отправка).
- [ ] Если таб уже привязан — пункт «Отвязать от tmux (`window`)».
- [ ] Привязанный таб визуально помечен в табстрипе (иконка + tooltip
      `session:window`).
- [ ] `Ctrl+Enter` идёт по цепочке Explicit → Last → Fallback (picker).
- [ ] Привязка резолвится по имени `session:window` → активная pane окна.
- [ ] Окно привязки не найдено → toast + picker (graceful, без отправки «не туда»).
- [ ] Привязка переживает перезапуск приложения (IndexedDB).
- [ ] `Ctrl+Shift+Enter` по-прежнему всегда открывает picker.
- [ ] Старые tmux-настройки (target mode / pane id) удалены из Settings, стора,
      db, persistence. `tmuxAutoSubmit` работает.
- [ ] Браузер (не Tauri): `Ctrl+Enter` → clipboard-fallback, без попыток shell.

## Scope

### Данные (`editorStore.ts`)
- `Tab.tmuxBinding?: { session: string; window: string }`.
- `setTabBinding(id, binding | null)` — immutable update, `null` снимает привязку.

### Резолв (`useTmuxSend.ts`)
- `TmuxPickTarget = { paneId, session, window, label }` — то, что отдаёт picker.
- `resolveTmuxBinding({session, window}): Promise<string | null>` — `listTmuxTargets`
  → найти session→window по имени → активная (или первая) pane; ошибка/не найдено
  → `null`.

### Picker (`TmuxTargetPicker.tsx`)
- `onPick(target: TmuxPickTarget)` (раньше отдавал `(paneId, label)`).
- Опц. `mode?: "send" | "bind"` — только для подписи футера («отправить» / «привязать»).

### Clean sweep старых настроек
- `settingsStore.ts` — убрать `tmuxTargetMode`, `tmuxTargetPane` + сеттеры.
- `db.ts` — убрать из `loadSession`/`saveSession` (сигнатура меняется).
- `useSessionPersistence.ts` — убрать из restore/hydrate/persist.
- `SettingsPanel.tsx` — убрать UI «Target pane» + из reset. Оставить Auto-submit.
- Осиротевшие meta-ключи в IndexedDB — безвредны, миграция не нужна.

### TabBar (`TabBar.tsx`)
- Контекстное меню: bind / unbind пункты.
- Индикатор привязки на табе + tooltip.
- `tabsMetaEqual` — добавить сравнение `tmuxBinding` (иначе индикатор не
  перерисуется).
- Новый проп `onBindTmux(tabId)` (открыть bind-picker в App); unbind — через стор.

### App (`App.tsx`)
- `tmuxPicker: null | { mode: "send" } | { mode: "bind"; tabId }` вместо boolean.
- `handleTmuxSend` — async цепочка; браузер-guard в начале.
- `handlePicked(target)` — send или bind по `tmuxPicker.mode`.
- Убрать использование `tmuxTargetMode`/`tmuxTargetPane`.

## Затрагиваемые файлы

```txt
web/src/store/editorStore.ts                  # Tab.tmuxBinding + setTabBinding
web/src/hooks/useTmuxSend.ts                  # TmuxPickTarget + resolveTmuxBinding
web/src/components/TmuxPicker/TmuxTargetPicker.tsx  # onPick richer + mode
web/src/store/settingsStore.ts                # - tmuxTargetMode/Pane
web/src/lib/db.ts                             # - из load/save
web/src/hooks/useSessionPersistence.ts        # - из restore/persist
web/src/components/Settings/SettingsPanel.tsx # - target pane UI
web/src/components/TabBar/TabBar.tsx          # ctx menu + индикатор + equality
web/src/App.tsx                               # цепочка + picker modes + wiring
```

Desktop/Tauri и `capabilities/default.json` — не трогать.

## Test plan (manual, Tauri + tmux)

1. tmux: окна `claude` и `codex`.
2. Привязать таб A → `claude`, таб B → `codex` (контекстное меню).
3. Из таба A `Ctrl+Enter` → летит в claude, **даже когда активно окно codex**.
4. Из таба B `Ctrl+Enter` → в codex.
5. Непривязанный таб: первый `Ctrl+Enter` → picker; после выбора — sticky (last).
6. Перезапустить приложение → привязки A/B сохранились.
7. Закрыть окно `codex` в tmux → `Ctrl+Enter` из таба B → toast + picker.
8. Отвязать таб A → `Ctrl+Enter` падает на last/picker.
9. Settings: «Target pane» исчез, Auto-submit работает.

Verification:
```bash
cd web && bun tsc --noEmit && bun lint
```

## Явные отказы

- НЕ выносить `remember`/`auto-bind` тумблеры в Settings-UI (hardcode дефолтами).
- НЕ персистить `lastTarget`.
- НЕ биндить по `@id`.
- НЕ добавлять Tauri permissions.

## Definition of done

- Acceptance criteria checked.
- `cd web && bun tsc --noEmit && bun lint` — clean.
- Manual test plan пройден на реальном tmux.
