# Task 01 — tmux send-keys (Ctrl+Enter)

**Status:** done
**Priority:** #1 (см. [docs/ROADMAP.md](../docs/ROADMAP.md))
**Owner:** human-planner (Claude Opus) + executor (Codex)

## Цель

Закрыть исходную боль, ради которой создавался Sendoff: написал промпт в редакторе → одной комбинацией клавиш отправить его в активную tmux pane (где запущен Claude Code или другая CLI), без переключения окон, копирования и вставки.

Текущий flow: написал → Ctrl+A → Ctrl+C → переключился в tmux → Ctrl+V → Enter. **5 действий вместо одного.**

Целевой flow: написал → Ctrl+Enter → готово.

## Acceptance criteria

- [x] В редакторе работает горячая клавиша `Ctrl+Enter` → отправляет содержимое **активного таба** в выбранную tmux pane.
- [x] Если выделен фрагмент текста — отправляется только выделение.
- [x] Цель (target tmux pane) настраивается в Settings: либо «активная pane» (через `tmux display-message -p '#{pane_id}'`), либо явный pane id.
- [x] После отправки — toast «Отправлено в tmux: <pane>» с количеством символов.
- [x] Если tmux не запущен или target pane не существует — toast с понятной ошибкой, не падает.
- [x] Опционально: после текста передаётся `Enter` (настраивается флагом «auto-submit»). По умолчанию — да.
- [x] Шорткат отображается в `ShortcutsModal`.

## Архитектурный план

### 1. Tauri side — shell-команда

В `src-tauri` добавить плагин `tauri-plugin-shell` (если ещё не установлен) или использовать `Command::new` через `tauri-plugin-process`.

Permission в `src-tauri/capabilities/default.json`:

```json
{
  "identifier": "shell:allow-execute",
  "allow": [
    { "name": "tmux", "cmd": "tmux", "args": true }
  ]
}
```

Точечный allow только для бинарника `tmux` — не открываем доступ ко всему shell.

⚠️ Это меняет threat model: ранее был strict local-first без shell-доступа. Обновить раздел "NEVER" и "Tauri Permissions" в `CLAUDE.md` после реализации — отметить, что `tmux` теперь разрешён, остальной shell — нет.

### 2. Web side — frontend

Новый хук `web/src/hooks/useTmuxSend.ts`:

```ts
export function useTmuxSend() {
  return async (text: string, opts: { target?: string; submit?: boolean }) => {
    if (!isTauri()) return; // в браузере — копировать в clipboard как fallback
    const { Command } = await import('@tauri-apps/plugin-shell');
    const target = opts.target ?? '{last}'; // tmux: последняя активная pane
    // tmux send-keys -t <target> "$text"
    await Command.create('tmux', ['send-keys', '-t', target, text]).execute();
    if (opts.submit ?? true) {
      await Command.create('tmux', ['send-keys', '-t', target, 'Enter']).execute();
    }
  };
}
```

⚠️ Нюанс: `text` может содержать кавычки/спецсимволы. Передавать как отдельный argv-элемент (а не через shell-конкатенацию) — `Command.create` это сделает безопасно.

⚠️ Длинные тексты (>4KB) tmux может обрезать. Если упадём — рассмотреть `tmux load-buffer` + `paste-buffer` как альтернативу.

### 3. Шорткат

В `web/src/hooks/useKeyboardShortcuts.ts` добавить:

```ts
useHotkey('ctrl+enter', (e) => {
  e.preventDefault();
  const tab = useEditorStore.getState().activeTab;
  if (!tab) return;
  const text = getSelectionOrFullContent(tab);
  sendToTmux(text, { submit: settings.tmuxAutoSubmit });
}, { allowInTextarea: true });
```

`allowInTextarea: true` — обычно хоткеи отключены внутри textarea, тут наоборот.

### 4. Settings UI

В `SettingsPanel.tsx` добавить секцию "tmux integration":

- Toggle: «Auto-submit (нажать Enter после текста)» — bool, default true.
- Input: «Target pane» — string, default `{last}`. Help text: `{last}` = последняя активная pane, `%0` или `0.1` = явный id, см. `tmux list-panes -a`.

Persist в `useSessionPersistence.ts` через `settingsStore`.

## Затрагиваемые файлы (estimated)

```
src-tauri/Cargo.toml                              # +tauri-plugin-shell
src-tauri/src/lib.rs                              # .plugin(tauri_plugin_shell::init())
src-tauri/capabilities/default.json               # +shell:allow-execute для tmux
web/src/hooks/useTmuxSend.ts                      # NEW
web/src/hooks/useKeyboardShortcuts.ts             # +ctrl+enter handler
web/src/components/Settings/SettingsPanel.tsx     # +tmux section
web/src/components/ShortcutsModal/ShortcutsModal.tsx  # +Ctrl+Enter в список
web/src/store/settingsStore.ts                    # +tmuxAutoSubmit, tmuxTarget
```

## Test plan

Manual (UI и tmux нельзя автотестить без harness):

1. Запустить tmux, в одной pane запустить `cat` (он будет эхо-выводить полученное).
2. В Sendoff написать «hello world», Ctrl+Enter → в pane должно появиться `hello world\n`.
3. Выделить часть текста → Ctrl+Enter → отправляется только выделение.
4. Отключить auto-submit в settings → Ctrl+Enter → текст в pane без Enter.
5. Указать несуществующий target pane → toast с ошибкой, приложение работает.
6. Очень длинный текст (10KB) — отправляется без обрезания.

## Зависимости

- `tauri-plugin-shell` (или эквивалент) на стороне Rust.
- `@tauri-apps/plugin-shell` на стороне TS.

## Риски / open questions

- **Cross-platform.** На macOS tmux обычно есть. На Windows tmux нет — но Sendoff-desktop пока Linux-only (см. позиционирование/install.sh). Если когда-нибудь Windows — будет другой механизм (PowerShell? Windows Terminal API?). Сейчас Linux/macOS only, ОК.
- **Threat model expansion.** Добавление shell-доступа (даже точечно к tmux) — отход от strict local-first. Зафиксировать в `CLAUDE.md` явно: «`tmux` allowed, остальной shell — нет».
- **tmux буферизация.** Длинные тексты (>4KB) могут обрезаться. Если столкнёмся — переключиться на `load-buffer` + `paste-buffer`.

## References

- [docs/ROADMAP.md](../docs/ROADMAP.md) — приоритет #1, история обоснования.
- Tauri shell plugin: https://v2.tauri.app/plugin/shell/
- tmux send-keys: `man tmux` → SEND-KEYS.

## Definition of done

- [x] Все Acceptance criteria checked.
- [x] `cd web && bun tsc --noEmit && bun lint` — clean.
- [x] `cd src-tauri && cargo check` — clean.
- [x] Threat model раздел в `CLAUDE.md` обновлён (tmux в whitelist).
- [x] ShortcutsModal в UI отражает новый шорткат.
- [x] Manual test plan пройден (вручную в `bun dev`): full tab и selection приходят в `cat` внутри tmux.
- [x] Коммиты:
  - `feat(tmux): отправка промпта в pane по Ctrl+Enter` в `web`.
  - `feat(tmux): добавить shell-доступ для отправки в pane` в `sendoff-desktop`.
