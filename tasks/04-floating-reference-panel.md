# Task 04 — floating reference panel

**Status:** done
**Priority:** #4 (см. [docs/ROADMAP.md](../docs/ROADMAP.md))
**Owner:** human-planner (Claude Opus) + executor (Codex)

## Цель

Дать место для временного reference/context рядом с основным prompt: фрагменты ошибки, требования, заметки из другой сессии, список ограничений. Сейчас это приходится держать в голове, в отдельном табе или во внешнем окне.

Это остаётся в рамках Rewrite как prompt-first editor. Reference panel — вспомогательная scratch-зона для текущей формулировки prompt, не knowledge base и не workspace system.

## Принятое решение

Для v0.1 делать **panel внутри главного окна**, не отдельное OS-окно.

Причины:

- не нужны новые Tauri permissions;
- меньше lifecycle/window-management сложности;
- быстрее получить dogfood value;
- текущая архитектура уже имеет side panels.

Отдельное OS-окно можно вернуться обсудить позже, если появится реальная боль “хочу вынести reference на другой монитор”.

## Acceptance criteria

- [x] В UI есть reference panel, открываемая отдельной командой/shortcut.
- [x] Panel можно открыть и закрыть без потери текста в текущей сессии.
- [x] В panel есть textarea для свободного reference-текста.
- [x] Текст reference сохраняется между перезапусками вместе с local app state.
- [x] Panel не меняет содержимое активного prompt сама по себе.
- [x] Editor остаётся usable при открытой panel: layout не перекрывает основной textarea.
- [x] Есть быстрый action “вставить reference в prompt” или “скопировать reference в clipboard” — выбрать самый простой вариант по существующим APIs.
- [x] Shortcut отображается в `ShortcutsModal`.

## Scope

UI:

- in-app side panel, визуально в семье `PresetsPanel` / `AIPromptPanel` / `SettingsPanel`;
- заголовок `Reference`;
- textarea с monospace styling;
- compact toolbar:
  - close;
  - clear;
  - insert/copy action.

State:

- отдельный Zustand store или расширение существующего settings/session persistence, что проще по текущему коду;
- persistence через существующий IndexedDB/local persistence pattern;
- без миграций и backwards-compat shims.

Shortcut:

- Предпочтительно `Ctrl+R`, если не конфликтует с текущими app shortcuts.
- Если конфликтует с browser reload слишком раздражающе в dev, выбрать `Ctrl+Shift+R` или command-only.

## Затрагиваемые файлы (estimated)

```txt
web/src/App.tsx
web/src/hooks/useKeyboardShortcuts.ts
web/src/hooks/useSessionPersistence.ts
web/src/store/referenceStore.ts                  # NEW, если нужен отдельный store
web/src/components/ReferencePanel/ReferencePanel.tsx # NEW
web/src/components/ShortcutsModal/ShortcutsModal.tsx
web/src/lib/db.ts                                # если persistence удобнее держать там
```

Desktop/Tauri files не трогать.

## Test plan

Manual:

1. Открыть reference panel shortcut/command.
2. Ввести reference text, закрыть panel, открыть снова → текст остался.
3. Перезапустить app → reference text восстановился.
4. Проверить, что основной prompt не изменяется при обычном typing в reference.
5. Проверить insert/copy action.
6. Проверить clear action.
7. Проверить, что editor layout остаётся usable на обычной ширине окна.
8. Shortcut виден в `ShortcutsModal`.

Automated/verification:

```bash
cd web && bun tsc --noEmit && bun lint
```

Если меняется persistence или layout существенно:

```bash
cd web && bun run build
```

## Явные отказы для этой задачи

- Не делать отдельное OS-окно.
- Не делать multi-reference notes.
- Не делать folders/tags/search по reference.
- Не делать markdown preview для reference.
- Не делать linking reference к табам.
- Не добавлять Tauri permissions.

## Definition of done

- Acceptance criteria checked.
- `cd web && bun tsc --noEmit && bun lint` — clean.
- `cd web && bun run build` — clean.
- Manual test plan пройден.
