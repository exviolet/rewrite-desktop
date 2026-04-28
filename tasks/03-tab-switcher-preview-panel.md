# Task 03 — tab switcher preview panel

**Status:** done
**Priority:** #3 (см. [docs/ROADMAP.md](../docs/ROADMAP.md))
**Owner:** human-planner (Claude Opus) + executor (Codex)

## Цель

Усилить уже добавленный `Ctrl+T` tab switcher: сейчас он помогает найти таб, но preview слишком закрытый и не всегда даёт быстро понять, тот ли это prompt.

Нужен более наглядный preview выбранного таба без превращения Rewrite в workspace manager, knowledge base или tab organizer.

## Acceptance criteria

- [x] На desktop-width `TabSwitcher` показывает список табов и отдельную preview-панель выбранного таба.
- [x] Preview обновляется сразу при `ArrowUp` / `ArrowDown` и hover по результатам.
- [x] Preview показывает достаточно контента выбранного таба, чтобы визуально проверить prompt без открытия таба.
- [x] Если query совпал с content, preview показывает фрагмент вокруг найденного совпадения, а не только первую строку.
- [x] Совпадение в preview визуально подсвечивается.
- [x] Empty tab имеет спокойный empty-state в preview.
- [x] На narrow/mobile width layout остаётся одноколоночным и не ломает навигацию.
- [x] Keyboard flow остаётся прежним: `Ctrl+T`, `ArrowUp/ArrowDown`, `Enter`, `Escape`.

## Scope

Основной вариант:

```txt
[ search input ]

┌ tab list ─────────────┬ preview ─────────────────────┐
│ • #12 Title           │ First meaningful line          │
│   short preview       │                                │
│                       │ Full selected tab preview...   │
│ • #31 Another title   │ 10-15 lines, clamped           │
│                       │                                │
└───────────────────────┴───────────────────────────────┘
```

Поведение:

- desktop layout: two-column modal;
- left column: текущий список результатов, dirty dot, title, short preview, номер таба;
- right column: крупный preview выбранного результата;
- empty query: preview следует за выбранным recent tab;
- query по title/first line: preview может показывать начало таба;
- query по body content: preview должен центрироваться вокруг найденного фрагмента;
- стрелки и hover меняют selected result и preview без debounce.

Implementation notes:

- Начать с `web/src/components/TabSwitcher/TabSwitcher.tsx`.
- Если текущий `MatchResult` недостаточен для preview context, расширить его полями вроде `source: "title" | "preview" | "content"` и `indices`.
- Не добавлять Fuse.js или persistent index.
- Не менять store model.
- Не добавлять folders/tags/workspaces.

## Затрагиваемые файлы (estimated)

```txt
web/src/components/TabSwitcher/TabSwitcher.tsx
```

Возможные точечные изменения рядом допустимы только если они явно уменьшают дублирование.

## Test plan

Manual:

1. Открыть `Ctrl+T` при пустом query → виден список и preview выбранного таба.
2. Навигировать стрелками → preview меняется без задержки.
3. Навести мышью на другой результат → preview меняется.
4. Найти таб по title → Enter открывает выбранный таб.
5. Найти таб по слову из середины content → preview показывает контекст вокруг совпадения.
6. Проверить пустой tab → preview показывает empty-state.
7. Уменьшить ширину окна → layout остаётся читаемым, text не перекрывается.

Automated/verification:

```bash
cd web && bun tsc --noEmit && bun lint
```

Если меняются стили/layout существенно:

```bash
cd web && bun run build
```

## Явные отказы для этой задачи

- Не делать tab folders/tags/workspaces.
- Не делать отдельный tab management screen.
- Не менять persistence schema.
- Не вводить новый fuzzy/search dependency.
- Не делать preview editable внутри switcher.

## Definition of done

- Acceptance criteria checked.
- `cd web && bun tsc --noEmit && bun lint` — clean.
- `cd web && bun run build` — clean.
- Manual test plan пройден на реальной сессии с большим количеством табов.
