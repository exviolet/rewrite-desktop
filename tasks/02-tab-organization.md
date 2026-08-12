# Task 02 — tab organization (auto-title, fuzzy switcher, empty cleanup)

**Status:** done
**Priority:** #2 (см. [docs/ROADMAP.md](../docs/ROADMAP.md))
**Owner:** human-planner (Claude Opus) + executor (Codex)

## Цель

Снять текущую UX-боль после закрытия tmux-flow: накопилось 125-130 табов, среди них много `Untitled N`, навигация по горизонтальной ленте стала неэффективной.

Нужен быстрый способ:

1. понимать, что лежит в табе без ручного rename;
2. прыгать к нужному табу по fuzzy-поиску;
3. безопасно убирать пустой мусор.

Это остаётся в рамках позиционирования Sendoff как prompt-first editor. Это не workspace system, не knowledge base и не файловый проект-менеджер.

## Acceptance criteria

- [x] Таб автоматически получает имя из первой непустой строки содержимого.
- [x] Автоимя не перетирает ручное имя таба.
- [x] Уже существующие `Untitled N` табы получают автоимена при следующей загрузке/изменении, если у них есть содержимое.
- [x] В UI есть fuzzy-поиск по табам, который ищет по title и content preview.
- [x] Из fuzzy-поиска можно перейти к выбранному табу клавиатурой.
- [x] В fuzzy-поиске видны dirty-индикатор, title и короткий preview.
- [x] Есть действие cleanup пустых табов, которое закрывает только безопасно пустые табы.
- [x] Cleanup не удаляет активный единственный таб; после cleanup в приложении всегда остаётся хотя бы один таб.
- [x] Cleanup показывает toast с количеством закрытых табов.
- [x] Горячие клавиши отображаются в `ShortcutsModal`.

## Scope

### 1. Auto-title

Добавить в модель таба явный маркер ручного имени:

```ts
interface Tab {
  id: string;
  title: string;
  content: string;
  isDirty: boolean;
  createdAt: number;
  updatedAt: number;
  titleSource?: "auto" | "manual" | "file";
}
```

Правила:

- новые пустые табы создаются как `Untitled N`, `titleSource: "auto"`;
- `renameTab()` выставляет `titleSource: "manual"`;
- `addTabFromFile()` выставляет `titleSource: "file"`;
- auto-title применяется только к табам с `titleSource !== "manual" && titleSource !== "file"`;
- для старых табов без `titleSource`: если title матчится на `^Untitled \d+$`, считать auto; иначе считать manual;
- auto-title берёт первую непустую строку из `content`;
- normalize: `trim()`, collapse whitespace внутри строки до single space;
- длина: максимум 48 символов, дальше `...`;
- если content пустой — title остаётся `Untitled N`;
- обновлять auto-title в `updateContent()` без debounce: это реактивный UI-индикатор, задержки раздражают.

Не добавлять миграции IndexedDB: clean sweep/compat shim не нужен. Backfill можно сделать в `hydrate()` при нормализации загруженных табов.

### 2. Fuzzy tab switcher

Сделать отдельный компонент, не смешивать с Command Palette:

```txt
web/src/components/TabSwitcher/TabSwitcher.tsx
```

Горячая клавиша:

- `Ctrl+T` — открыть tab switcher.
- Внутри: `ArrowUp/ArrowDown`, `Enter`, `Escape`.

Почему `Ctrl+T`: в desktop-приложении это ожидаемый shortcut для tab navigation/search, а браузерный new-tab shortcut внутри Tauri не нужен. `Ctrl+N` уже создаёт новый Sendoff tab.

Поведение:

- список открывается modal overlay как Command Palette;
- input автофокусится;
- пустой query показывает последние обновлённые табы сверху (`updatedAt desc`), но активный таб не обязан быть первым;
- fuzzy search ищет по:
  - `title`;
  - первой непустой строке content;
  - остальному content с меньшим весом;
- результат показывает:
  - dirty dot;
  - title;
  - preview первой непустой строки или первые 80 символов content;
  - позицию таба (`#17`) маленьким muted текстом;
- `Enter` переключает `activeTabId` и закрывает switcher;
- мышиный click тоже переключает;
- если query ничего не нашёл — показать compact empty state.

Можно переиспользовать `fuzzyMatch()` из `CommandPalette`, но если копирование проще — допустимо. Абстракцию выносить только если это реально уменьшит код.

### 3. Empty cleanup

Добавить store action:

```ts
cleanupEmptyTabs: () => number;
```

Закрывать только табы, которые безопасно пустые:

- `content.trim() === ""`;
- `!isDirty`;
- нет manual/file title (`titleSource === "auto"` или legacy `Untitled N`);
- не единственный оставшийся таб.

Если активный таб попадает в cleanup:

- выбрать ближайший оставшийся таб справа, иначе слева;
- если все табы пустые, оставить один активный tab.

UI entry points:

- Command Palette: `Очистить пустые табы`;
- Tab context menu: `Закрыть пустые`;
- опционально Settings не трогать.

Toast:

- `Пустых табов нет` (`info`) если закрыто 0;
- `Закрыто пустых табов: N` (`success`) если N > 0.

## Затрагиваемые файлы (estimated)

```txt
web/src/store/editorStore.ts
web/src/hooks/useKeyboardShortcuts.ts
web/src/App.tsx
web/src/components/TabSwitcher/TabSwitcher.tsx      # NEW
web/src/components/TabBar/TabBar.tsx
web/src/components/ShortcutsModal/ShortcutsModal.tsx
web/src/components/CommandPalette/CommandPalette.tsx # возможно только reuse/copy fuzzy logic
web/src/lib/db.ts                                   # только если понадобится normalize helper nearby
```

Desktop/Tauri files не трогать.

## Test plan

Manual:

1. Создать новый таб, ввести `Explain this Rust lifetime issue` → title становится `Explain this Rust lifetime issue`.
2. Ввести первую строку длиннее 48 символов → title truncates with `...`.
3. Переименовать tab вручную → дальнейшие изменения content не меняют title.
4. Открыть файл → title остаётся file name, auto-title не перетирает.
5. Открыть `Ctrl+T`, найти tab по части title → Enter переключает active tab.
6. Найти tab по слову из preview/content → результат появляется.
7. Создать несколько пустых saved tabs, выполнить cleanup → они закрываются, toast показывает count.
8. Dirty пустой tab после ввода и стирания не закрывается, если `isDirty === true`.
9. При 1 пустом табе cleanup не оставляет приложение без tabs.
10. `Ctrl+T` отображается в `ShortcutsModal`.

Automated/verification:

```bash
cd web && bun tsc --noEmit && bun lint
```

## Риски / open questions

- **Legacy tabs.** Уже есть 125-130 табов без `titleSource`. Решение: normalize в `hydrate()` по title pattern, без IndexedDB migration.
- **Dirty semantics.** Сейчас `updateContent()` всегда ставит `isDirty: true`. Значит tab, где пользователь ввёл и стёр текст, cleanup не удалит. Это консервативно и правильно.
- **Shortcut conflict.** `Ctrl+T` в браузере создаёт новый browser tab, но Sendoff target — Tauri desktop; в browser fallback можно всё равно перехватывать внутри app.
- **Performance.** 130 табов мало для сложных индексов. Делать простой in-memory filter в компоненте. Не вводить Fuse.js dependency, пока не доказана необходимость.

## Явные отказы для этой задачи

- Не делать workspaces.
- Не делать folders/tags.
- Не делать persistent search index.
- Не делать bulk delete для непустых табов.
- Не делать миграцию IndexedDB.
- Не превращать Command Palette в универсальный launcher для всего; tab switcher может быть отдельным modal.

## Definition of done

- Acceptance criteria checked.
- `cd web && bun tsc --noEmit && bun lint` — clean.
- `cd web && bun run build` — clean.
- Manual test plan пройден на реальной сессии с большим количеством табов.
- Roadmap обновлён после реализации: Task 02 → `done`.
