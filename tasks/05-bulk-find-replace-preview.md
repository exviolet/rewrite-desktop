# Task 05 — bulk find & replace with preview

**Status:** done
**Priority:** #5 (см. [docs/ROADMAP.md](../docs/ROADMAP.md))
**Owner:** human-planner (Claude Opus) + executor (Codex)

## Цель

Сделать быстрый ad-hoc bulk replace для активного prompt: несколько find/replace пар, preview количества замен и явное подтверждение перед применением.

Это utility внутри prompt-first editor. Не pipeline-builder и не новая система пресетов.

## Acceptance criteria

- [x] В `FindReplacePanel` есть режим bulk replace для активного таба.
- [x] Можно добавить, удалить и редактировать несколько replacement pairs.
- [x] Каждая пара поддерживает `from`, `to`, `caseSensitive`, `wholeWord`.
- [x] Bulk preview показывает, какие пары сработают и сколько замен будет сделано.
- [x] Preview считается без изменения текущего prompt.
- [x] Apply применяет все пары последовательно к активному табу одним `updateContent()`.
- [x] Если совпадений нет, apply disabled или показывает non-destructive state.
- [x] Empty `from` pairs игнорируются.
- [x] Existing single find/replace flow остаётся рабочим.
- [x] Shortcut/entry point остаётся `Ctrl+H`; отдельный глобальный shortcut не нужен.

## Scope

UI:

- расширить текущий `web/src/components/FindReplace/FindReplacePanel.tsx`;
- добавить компактный toggle `Single` / `Bulk` только в `findReplace` mode;
- bulk section:
  - список rows `from -> to`;
  - buttons add/delete row;
  - per-row toggles `Aa` и `word`;
  - preview block с total count и rows that match;
  - apply button.

Logic:

- переиспользовать `ReplacePair`, `previewReplacePairs()` и `applyReplacePairs()` из `replaceEngine`;
- при apply использовать result из preview, чтобы preview/apply не расходились;
- не сохранять bulk pairs в persistence на этом шаге.

## Затрагиваемые файлы (estimated)

```txt
web/src/components/FindReplace/FindReplacePanel.tsx
web/src/lib/replaceEngine.ts # только если нужно небольшое helper-расширение
```

Desktop/Tauri files не трогать.

## Test plan

Manual:

1. Открыть `Ctrl+H`, single replace работает как раньше.
2. Переключиться в bulk mode.
3. Добавить 2-3 пары, preview показывает counts.
4. Проверить `caseSensitive`.
5. Проверить `wholeWord`.
6. Проверить empty `from` pair — не влияет на preview/apply.
7. Apply меняет активный prompt одним действием.
8. При no matches apply disabled / не меняет prompt.
9. Закрыть/открыть panel — persistence bulk pairs не требуется.

Automated/verification:

```bash
cd web && bun tsc --noEmit && bun lint
```

Если layout менялся заметно:

```bash
cd web && bun run build
```

## Явные отказы для этой задачи

- Не делать chained presets/live transformation.
- Не сохранять ad-hoc bulk pairs автоматически.
- Не делать import/export bulk pairs.
- Не делать multi-tab replace.
- Не делать preview полноценным diff viewer.

## Definition of done

- Acceptance criteria checked.
- `cd web && bun tsc --noEmit && bun lint` — clean.
- `cd web && bun run build` — clean.
- Manual test plan пройден.
