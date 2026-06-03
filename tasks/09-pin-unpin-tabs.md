# Task 09 — pin/unpin табов

**Status:** active
**Priority:** #10 (см. [docs/ROADMAP.md](../docs/ROADMAP.md))
**Owner:** human-planner (Claude Opus) + executor (**Codex**)

> Спек детальный намеренно: исполнитель — Codex. Где упрёшься в неясность —
> оставь TODO-комментарий, не угадывай.

## Цель

Закрепление табов: защитить важные табы (план, активный агент, reference) от
хаоса 75 Untitled и массовых чисток. Pinned уезжают в левую зону, защищены от
bulk-close, переживают рестарт.

## Решения (зафиксированы 2026-06-03)

- **Ctrl+P → toggle pin активного таба** (был command palette).
- **Command palette → Ctrl+Shift+P** (переезд).
- **Pinned защищены** от «закрыть остальные / сохранённые / справа» и cleanup
  пустых. Прямое закрытие (`Ctrl+W`, средняя кнопка, ×) pinned-таб всё равно
  закрывает.
- **Pinned-зона слева:** pinned всегда левее обычных. При закреплении таб
  переезжает в конец pinned-блока; при откреплении — в начало обычного блока.
  Drag-reorder — в пределах своей зоны (cross-zone дроп снапается к границе).
- **Persistence:** `pinned` — поле на `Tab` (авто-персист/очистка, как
  `tmuxBinding`).

## Acceptance criteria

- [ ] `Tab.pinned?: boolean`; экшен `togglePin(id)`.
- [ ] `Ctrl+P` переключает pin активного таба. Повторный `Ctrl+P` на закреплённом
      активном табе — открепляет (toggle).
- [ ] Command palette переехал на `Ctrl+Shift+P` (Ctrl+P его больше не открывает).
- [ ] Контекстное меню таба (ПКМ): «Закрепить таб» / «Открепить таб» вверху.
- [ ] Закреплённый таб визуально помечен (pin-иконка в табе).
- [ ] Pinned-табы рендерятся левее обычных; инвариант держится при pin/unpin,
      reorder, рестарте.
- [ ] При pin таб уходит в конец pinned-блока; при unpin — в начало обычного.
- [ ] Bulk-close («закрыть остальные/сохранённые/справа», cleanup пустых) НЕ
      трогает pinned.
- [ ] Прямое закрытие pinned (`Ctrl+W`, средняя кнопка, ×) — закрывает как обычно.
- [ ] Pinned состояние переживает перезапуск (IndexedDB).
- [ ] `ShortcutsModal`: `Ctrl+P` = закрепить таб, `Ctrl+Shift+P` = command palette.
- [ ] `cd web && bun tsc --noEmit && bun lint` — clean.

## Scope (точная реализация)

### Данные — `web/src/store/editorStore.ts`

1. В `interface Tab` добавить `pinned?: boolean`.
2. В `interface EditorStore` добавить `togglePin: (id: string) => void`.
3. Хелпер (стабильная партиция, pinned-first):
   ```ts
   function partitionPinned(tabs: Tab[]): Tab[] {
     return [...tabs.filter((t) => t.pinned), ...tabs.filter((t) => !t.pinned)];
   }
   ```
   `filter` сохраняет относительный порядок → даёт ровно нужное поведение:
   только что закреплённый таб оказывается в конце pinned-блока, откреплённый —
   в начале обычного.
4. `togglePin`:
   ```ts
   togglePin: (id) => set((s) => {
     const tabs = s.tabs.map((t) =>
       t.id === id ? { ...t, pinned: !t.pinned, updatedAt: Date.now() } : t
     );
     return { tabs: partitionPinned(tabs) };
   }),
   ```
5. `reorderTab` — после splice применить партицию (cross-zone дроп снапается):
   ```ts
   reorderTab: (fromIndex, toIndex) => set((s) => {
     const tabs = [...s.tabs];
     const [moved] = tabs.splice(fromIndex, 1);
     tabs.splice(toIndex, 0, moved);
     return { tabs: partitionPinned(tabs) };
   }),
   ```
6. `hydrate` — применить партицию к загруженным:
   `tabs: partitionPinned(tabs.map(normalizeTab))`.
7. **Защита pinned от bulk-close** — исключить pinned в источниках:
   - `closeSavedTabs`: `tabs.filter((t) => !t.isDirty && !t.pinned)`
   - `closeOtherTabs(keepId)`: `tabs.filter((t) => t.id !== keepId && !t.pinned)`
   - `closeTabsToRight(id)`: `slice(idx+1).filter((t) => !t.pinned)`
   - `cleanupEmptyTabs`: в `canCleanupTab` (или при сборе `cleanupIds`) добавить
     `&& !tab.pinned`.
   - `closeTab` / `performClose` — **НЕ трогать** (прямое закрытие pinned работает).
8. `createTab` / `addTabFromFile` — без изменений (новый таб не pinned,
   добавляется в конец = в обычную зону естественно).

### Клавиатура — `web/src/hooks/useKeyboardShortcuts.ts`

- В `ShortcutCallbacks` добавить `onTogglePin?: () => void`.
- Заменить текущую ветку `if (ctrl && code === "KeyP")` на две (shift-вариант
  первым, как сделано для Enter/B):
  ```ts
  if (ctrl && e.shiftKey && code === "KeyP") { e.preventDefault(); callbacks?.onCommandPalette?.(); return; }
  if (ctrl && !e.shiftKey && code === "KeyP") { e.preventDefault(); callbacks?.onTogglePin?.(); return; }
  ```
  (`e.code`, не `e.key` — кириллица; см. гайд в web/CLAUDE.md.)

### Wiring — `web/src/App.tsx`

- Хендлер:
  ```ts
  const toggleActivePin = useCallback(() => {
    const id = useEditorStore.getState().activeTabId;
    if (id) useEditorStore.getState().togglePin(id);
  }, []);
  ```
- В `useKeyboardShortcuts({...})` добавить `onTogglePin: toggleActivePin`.
  (`onCommandPalette` остаётся как есть — теперь срабатывает на Ctrl+Shift+P.)
- В `paletteCommands` добавить: `{ id: "toggle-pin", label: "Закрепить/открепить таб", shortcut: "Ctrl+P", action: toggleActivePin }`. Добавить `toggleActivePin` в deps массива useMemo.

### TabBar — `web/src/components/TabBar/TabBar.tsx`

- `tabsMetaEqual`: добавить сравнение `tab.pinned === next[i].pinned` (иначе
  индикатор/порядок не перерисуются).
- Pin-индикатор в табе (рядом с dirty/tmux-индикаторами). Простая pin-иконка
  (SVG, ~11px), `title="Закреплён"`. Полноразмерный заголовок оставить (icon-only
  компактные pinned-табы — НЕ в этой задаче).
- Контекстное меню (`TabContextMenu`): добавить вверху пункт
  «Закрепить таб» / «Открепить таб» (по `tab.pinned`), `action` → `togglePin(id)`.
  Передать pinned-состояние таба и `onTogglePin` в меню (по аналогии с tmux
  bind/unbind, которые там уже есть).

### ShortcutsModal — `web/src/components/ShortcutsModal/ShortcutsModal.tsx`

- В группе «Панели»: `Ctrl+P` сейчас = «Command Palette». Поменять на
  `Ctrl+Shift+P` = «Command Palette».
- В группе «Табы»: добавить `Ctrl+P` = «Закрепить/открепить таб».

### Проверить — `web/src/components/CommandPalette/CommandPalette.tsx`

- Если внутри есть хардкод-подсказка «Ctrl+P» (placeholder/футер) — поправить на
  `Ctrl+Shift+P`. Если нет — ничего не делать.

## Затрагиваемые файлы

```txt
web/src/store/editorStore.ts                  # Tab.pinned, togglePin, partition, защита bulk-close
web/src/hooks/useKeyboardShortcuts.ts         # Ctrl+P → pin, Ctrl+Shift+P → palette
web/src/App.tsx                               # toggleActivePin + wiring + палитра
web/src/components/TabBar/TabBar.tsx          # индикатор + ctx-menu + equality
web/src/components/ShortcutsModal/ShortcutsModal.tsx
web/src/components/CommandPalette/CommandPalette.tsx  # только если есть хардкод Ctrl+P
```

Desktop/Tauri файлы — НЕ трогать.

## Test plan (manual)

1. `Ctrl+P` на табе → закрепляется, уезжает влево, появляется pin-иконка.
2. Повторный `Ctrl+P` на нём → открепляется, уезжает в начало обычной зоны.
3. ПКМ → «Закрепить/Открепить» делает то же.
4. `Ctrl+Shift+P` открывает command palette (Ctrl+P его больше не открывает).
5. Закрепить 2-3 таба, «закрыть остальные/сохранённые/справа», cleanup пустых →
   pinned остаются.
6. `Ctrl+W` / средняя кнопка / × на pinned → закрывается.
7. Drag-reorder pinned — в пределах левой зоны; обычный — в правой.
8. Перезапуск приложения → pinned сохранились, порядок зон сохранён.

Verification:
```bash
cd web && bun tsc --noEmit && bun lint
```

## Явные отказы

- НЕ делать icon-only компактные pinned-табы (только pin-иконка + полный титул).
- НЕ менять поведение прямого закрытия pinned.
- НЕ добавлять отдельную «pinned»-секцию/сепаратор-полоску (только сортировка).
- НЕ добавлять Tauri permissions.

## Definition of done

- Acceptance criteria checked.
- `cd web && bun tsc --noEmit && bun lint` — clean.
- Manual test plan пройден.
- Коммит на web feature-ветке `feature/pin-tabs` (создавать **внутри** `web/`:
  `cd web && git switch -c feature/pin-tabs`), русский Conventional Commit.
