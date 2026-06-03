# Task 07 — tmux target picker

**Status:** active
**Priority:** #8 (см. [docs/ROADMAP.md](../docs/ROADMAP.md))
**Owner:** human-planner (Claude Opus) + executor (Codex)

## Цель

Дать явный выбор tmux-таргета при отправке промпта, чтобы различать несколько
запущенных агентов (напр. Claude Code в окне `claude`, Codex в окне `codex`).
Сейчас `Ctrl+Enter` шлёт только в активную pane — это слепой таргет, когда у
тебя несколько окон с разными агентами.

Эта задача — **фаза A**: чисто аддитивный picker. Persistent tab-binding,
цепочка резолва на `Ctrl+Enter` и Settings-тумблеры — это **фаза B** (#9),
здесь НЕ делаем.

## Не-цели (фаза B, не трогать здесь)

- НЕ менять поведение существующего `Ctrl+Enter` (остаётся = активная pane).
- НЕ делать persistent привязку таб→окно.
- НЕ делать цепочку Explicit→Last→Modal на `Ctrl+Enter`.
- НЕ добавлять Settings-тумблеры.
- НЕ персистить `lastTarget` (только in-memory).

## Acceptance criteria

- [ ] `Ctrl+Shift+Enter` открывает модалку выбора tmux-таргета.
- [ ] Модалка показывает дерево: session → window → pane.
- [ ] Для окна виден `window_name` и `pane_current_command` (чтобы отличить
      `claude` от `codex` от `zsh`).
- [ ] Активное окно/pane визуально помечены.
- [ ] Выбор таргета (`Enter` / клик) отправляет текущий буфер туда — через
      существующий `set-buffer` → `paste-buffer` → `send-keys` flow.
- [ ] Последний выбранный таргет запоминается **in-memory** (Zustand, без
      персиста) и пре-выделяется при следующем открытии модалки.
- [ ] `ArrowUp/ArrowDown` навигация по строкам, `Enter` выбор, `Escape` закрытие.
- [ ] Фильтр-input для быстрого поиска по имени окна/команды.
- [ ] tmux не запущен / нет сессий → спокойный empty-state + toast, не краш.
- [ ] В браузере (не Tauri) `Ctrl+Shift+Enter` ведёт себя как текущий fallback
      (clipboard) либо no-op с info-toast — не пытаться звать shell.
- [ ] `ShortcutsModal` отображает `Ctrl+Shift+Enter`.

## Scope

### Чтение топологии tmux

Одной командой собрать всё дерево (capability уже разрешает `tmux` с `args:true`,
новые permissions НЕ нужны):

```txt
tmux list-panes -a -F '#{session_name}\t#{window_index}\t#{window_name}\t#{pane_id}\t#{pane_active}\t#{window_active}\t#{pane_current_command}'
```

Распарсить в дерево `session → window → pane`. Если команда вернёт ненулевой код
(tmux не запущен) — поймать, показать empty-state.

### Логика отправки (`useTmuxSend.ts`)

- Расширить `TmuxTarget` вариантом для явно выбранной pane:
  `{ mode: "pane"; pane: string }` уже есть — переиспользовать (picker отдаёт
  `pane_id`).
- Добавить функцию `listTmuxTargets(): Promise<TmuxTree>` (одна `list-panes -a`).
- Отправка по выбранному `pane_id` — существующим flow, без изменений.

### Стейт (`tmuxStore.ts` — NEW)

- In-memory Zustand store: `lastTarget: { pane: string; label: string } | null`,
  `setLastTarget`.
- **НЕ** подписывать в `useSessionPersistence` — не персистить.

### UI (`TmuxPicker/TmuxTargetPicker.tsx` — NEW)

- Modal overlay (как `GlobalSearchPanel`), input autofocus.
- Дерево session/window/pane, для окна — имя + current_command.
- Клавиатурная навигация, фильтр, пометка active.

### Wiring

- `useKeyboardShortcuts.ts`: добавить callback `onTmuxPicker`, повесить на
  `Ctrl+Shift+Enter` (`ctrl && e.shiftKey && code === "Enter"`). Поставить ДО
  существующей ветки `ctrl && code === "Enter"` (иначе она перехватит).
- `App.tsx`: состояние открытия модалки, проброс текущего буфера, на выбор —
  вызвать send + `setLastTarget`.

## Затрагиваемые файлы (estimated)

```txt
web/src/hooks/useTmuxSend.ts                       # listTmuxTargets + reuse send
web/src/hooks/useKeyboardShortcuts.ts              # Ctrl+Shift+Enter
web/src/store/tmuxStore.ts                         # NEW (in-memory lastTarget)
web/src/components/TmuxPicker/TmuxTargetPicker.tsx # NEW
web/src/App.tsx                                     # modal state + wiring
web/src/components/ShortcutsModal/ShortcutsModal.tsx
```

Desktop/Tauri файлы и `capabilities/default.json` — **не трогать** (tmux уже
разрешён).

## Test plan

Manual (в Tauri-сборке, с запущенным tmux):

1. Запустить 2–3 tmux-окна с разными командами (напр. `claude`, второе с `node`,
   третье `zsh`).
2. `Ctrl+Shift+Enter` → модалка показывает все окна с именами и командами.
3. Выбрать конкретное окно → текст улетает строго туда, не в активное.
4. Повторный `Ctrl+Shift+Enter` → последний таргет пре-выделен.
5. `Ctrl+Enter` по-прежнему шлёт в активную pane (поведение не изменилось).
6. Убить tmux-сервер → `Ctrl+Shift+Enter` показывает empty-state + toast, не
   крашится.
7. Shortcut виден в `ShortcutsModal`.

Verification:

```bash
cd web && bun tsc --noEmit && bun lint
```

Если layout/сборка заметно менялись:

```bash
cd web && bun run build
```

## Явные отказы для этой задачи

- Не менять `Ctrl+Enter` (фаза B).
- Не персистить таргет / не делать tab-binding (фаза B).
- Не добавлять Settings-UI (фаза B).
- Не добавлять Tauri permissions.
- Не парсить tmux несколькими вызовами там, где хватает одного `list-panes -a`.

## Definition of done

- Acceptance criteria checked.
- `cd web && bun tsc --noEmit && bun lint` — clean.
- Manual test plan пройден на реальном tmux.
