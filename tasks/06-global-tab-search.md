# Task 06 — global tab search

**Status:** active
**Priority:** #6 (см. [docs/ROADMAP.md](../docs/ROADMAP.md))
**Owner:** human-planner (Claude Opus) + executor (Codex)

## Цель

Добавить поиск по всем открытым табам: найти конкретный термин, ошибку или фрагмент prompt среди накопленной сессии и перейти к точному совпадению.

Это не workspace/project search. Область поиска — только open tabs в текущей local session.

## Acceptance criteria

- [ ] `Ctrl+Shift+D` открывает global search UI.
- [ ] Поиск идёт по content всех открытых табов.
- [ ] Results grouped by tab: title, номер таба, count matches.
- [ ] Для каждого совпадения показывается snippet вокруг match.
- [ ] Match в snippet визуально подсвечен.
- [ ] Click/Enter по result открывает соответствующий tab.
- [ ] После перехода editor подсвечивает конкретный match.
- [ ] Поддерживаются `caseSensitive` и `regex`, как в локальном find.
- [ ] Empty query показывает спокойный empty-state, не список всех табов.
- [ ] No matches показывает compact empty-state.
- [ ] `ShortcutsModal` отображает `Ctrl+Shift+D`.

## Scope

UI:

- отдельный компонент:

```txt
web/src/components/GlobalSearch/GlobalSearchPanel.tsx
```

- modal/panel overlay, не side panel;
- input autofocus;
- grouped list with snippets;
- keyboard:
  - `ArrowUp/ArrowDown` navigate result rows;
  - `Enter` open selected match;
  - `Escape` close.

Logic:

- reuse `findMatches()` from `replaceEngine`;
- results computed in-memory from `tabs`;
- no persistent index;
- no filesystem access;
- no replace in this task.

Editor jump:

- when opening a result, set active tab and set local highlight to that match;
- exact scrolling to match is nice-to-have, not required for first version.

## Затрагиваемые файлы (estimated)

```txt
web/src/App.tsx
web/src/hooks/useKeyboardShortcuts.ts
web/src/components/GlobalSearch/GlobalSearchPanel.tsx # NEW
web/src/components/ShortcutsModal/ShortcutsModal.tsx
```

Optional:

```txt
web/src/components/Editor/Editor.tsx # only if needed for scroll-to-match
```

Desktop/Tauri files не трогать.

## Test plan

Manual:

1. Открыть `Ctrl+Shift+D`.
2. Найти слово, встречающееся в нескольких табах.
3. Проверить grouping по табам и match counts.
4. Проверить snippets и подсветку match.
5. `ArrowUp/ArrowDown` меняет selected result.
6. `Enter` открывает tab с выбранным match и подсвечивает match.
7. Click по result делает то же самое.
8. Проверить `caseSensitive`.
9. Проверить `regex`.
10. Empty/no matches states выглядят нормально.
11. Shortcut отображается в `ShortcutsModal`.

Automated/verification:

```bash
cd web && bun tsc --noEmit && bun lint
```

Если layout менялся заметно:

```bash
cd web && bun run build
```

## Явные отказы для этой задачи

- Не делать global replace.
- Не искать по filesystem.
- Не делать persistent search index.
- Не делать workspace/project model.
- Не добавлять Tauri permissions.

## Definition of done

- Acceptance criteria checked.
- `cd web && bun tsc --noEmit && bun lint` — clean.
- Manual test plan пройден.
