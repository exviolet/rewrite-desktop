# Task 10 — Reference panel → live tab

**Status:** paused / under review
**Priority:** #11 (см. [docs/ROADMAP.md](../docs/ROADMAP.md))
**Owner:** human-planner (Claude Opus) + executor (**Codex**)

> **2026-06-11:** Реализация выполнена Codex (tsc + lint exit 0), но **дизайн
> под вопросом** после ревью. Не мержить. Код сохранён на ветке web
> `feature/reference-live-tab` (коммит `70d9f6c`), не в `master`. Решение по
> судьбе фичи — отложено.

> Спек детальный намеренно: исполнитель — Codex. Где упрёшься в неясность —
> оставь TODO-комментарий, НЕ угадывай. Desktop/Tauri файлы НЕ трогать.

## Цель

Апгрейд reference panel: вместо только scratchpad — уметь **зеркалить живой
таб** (read-only, обновляется пока правишь тот таб). Это замена отклонённому
split-view (см. ROADMAP стр. 58): держать перед глазами таб с контекстом/
требованиями, пока пишешь промпт в активном табе, без копипасты-снапшота.

## Решения (зафиксированы grill-сессией 2026-06-05)

- **Dual mode.** Reference panel = либо **scratch** (текущая свободная textarea,
  не трогаем), либо **tab** (read-only зеркало выбранного таба). Переключение —
  в шапке панели.
- **Read-only зеркало + pencil.** В tab-режиме textarea `readOnly`, показывает
  живой `content` привязанного таба. Кнопка-карандаш в шапке → **swap (A/B
  bounce)**: привязанный таб становится активным, а reference перепривязывается
  на таб, который только что был активным. Кликаешь pencil — прыгаешь между двумя
  табами, панель всегда показывает «другой». Editable-split НЕ делаем.
- **3 способа привязки** (все → один экшен `linkTab(id)`):
  1. **Searchable popover** в шапке панели (НЕ сырой `<select>` — у пользователя
     75+ табов). Кнопка с текущим источником → поповер с фильтром по тайтлу
     (в духе `TabSwitcher`, Ctrl+T) + верхний пункт «Scratch».
  2. **ПКМ по табу** → «Показать в reference».
  3. **Drag&Drop**: тащишь таб из tab-bar на панель → привязка. TabBar уже на
     нативном HTML5 DnD — добавить `tab.id` в `dataTransfer`, панель ловит drop.
- **Linked tab закрыт** → плейсхолдер «Таб закрыт» + кнопка «Вернуться к scratch».
  Не терять привязку молча, не протухать снапшотом.
- **«Очистить»** в tab-режиме заменяется на **«Отвязать»** (→ scratch).
  **«Вставить»** работает в обоих режимах (в tab — вставляет живой контент таба).
- **Persistence:** `mode` + `linkedTabId` — в `referenceStore` + `meta`-store
  (key-value, без schema bump, без миграции).
- Тоггл панели остаётся `Ctrl+R` (не трогаем).

## Acceptance criteria

- [ ] `referenceStore`: поля `mode: "scratch" | "tab"`, `linkedTabId: string | null`;
      экшены `linkTab(id)`, `unlink()`. `hydrate` принимает `mode`/`linkedTabId`.
- [ ] Шапка панели: searchable popover с фильтром по тайтлу + пункт «Scratch».
      Выбор таба → `linkTab`, выбор «Scratch» → `unlink`.
- [ ] Tab-режим: `readOnly` textarea показывает **живой** `content` привязанного
      таба (правишь тот таб активным → зеркало обновляется без перезагрузки).
- [ ] Pencil-кнопка (видна только в tab-режиме) → swap: `setActiveTab(linkedId)` +
      `linkTab(prevActiveId)`. Если `prevActive === linkedId` — no-op-safe.
- [ ] ПКМ по табу → пункт «Показать в reference» (вверху, рядом с pin/tmux).
- [ ] D&D таба из tab-bar на панель → привязка. Drop-зона визуально подсвечивается.
- [ ] Linked tab закрыт (id есть, таба нет) → плейсхолдер + кнопка «Вернуться к
      scratch».
- [ ] Tab-режим: «Очистить» → «Отвязать»; «Вставить» вставляет живой контент таба.
- [ ] `mode`/`linkedTabId` переживают перезапуск (IndexedDB meta).
- [ ] Scratch-режим работает ровно как раньше (регрессий нет).
- [ ] `cd web && bun tsc --noEmit && bun lint` — clean.

## Scope (точная реализация)

### Store — `web/src/store/referenceStore.ts`

1. Расширить интерфейс:
   ```ts
   type ReferenceMode = "scratch" | "tab";
   interface ReferenceStore {
     text: string;
     width: number;
     mode: ReferenceMode;          // NEW
     linkedTabId: string | null;   // NEW
     setText: (text: string) => void;
     setWidth: (width: number) => void;
     clear: () => void;            // чистит scratch text (как было)
     linkTab: (tabId: string) => void;   // NEW
     unlink: () => void;                  // NEW
     hydrate: (data: { text: string; width: number; mode: ReferenceMode; linkedTabId: string | null }) => void;
   }
   ```
2. Дефолты: `mode: "scratch"`, `linkedTabId: null`.
3. Экшены:
   ```ts
   linkTab: (tabId) => set({ mode: "tab", linkedTabId: tabId }),
   unlink: () => set({ mode: "scratch", linkedTabId: null }),
   ```
4. `hydrate` — выставить все 4 поля (`mode`/`linkedTabId` с дефолтами, если undefined).
   `clampReferenceWidth(width)` — как сейчас.

### Persistence — `web/src/lib/db.ts`

- `loadSession`: добавить
  ```ts
  const referenceMode = (await db.get("meta", "referenceMode")) as string | undefined;
  const referenceLinkedTabId = (await db.get("meta", "referenceLinkedTabId")) as string | undefined;
  ```
  В return-объект:
  ```ts
  referenceMode: referenceMode === "tab" ? "tab" : "scratch",
  referenceLinkedTabId: referenceLinkedTabId ?? null,
  ```
- `saveSession`: добавить два позиционных параметра в конец сигнатуры
  `referenceMode: string, referenceLinkedTabId: string | null` и
  ```ts
  await metaStore.put(referenceMode, "referenceMode");
  await metaStore.put(referenceLinkedTabId ?? "", "referenceLinkedTabId");
  ```
  (Пустая строка при `null` — нормализуется в `loadSession`: `?? null` не
  сработает на `""`, поэтому в load использовать `referenceLinkedTabId || null`.)

### Persistence hook — `web/src/hooks/useSessionPersistence.ts`

- В `loadSession().then(...)` деструктурировать `referenceMode, referenceLinkedTabId`
  и передать в `useReferenceStore.getState().hydrate({ text, width, mode, linkedTabId })`.
- В `persist()`: вытащить `mode, linkedTabId` из стора и добавить в вызов
  `saveSession(..., referenceText, referenceWidth, mode, linkedTabId)`.

### TabBar — `web/src/components/TabBar/TabBar.tsx`

1. **D&D источник.** В `handleTabDragStart` (где `dataTransfer.setData("text/plain", String(index))`)
   добавить id таба:
   ```ts
   e.dataTransfer.setData("application/x-rewrite-tab-id", tabs[index].id);
   ```
   (reorder продолжает читать `text/plain` index — не трогать.)
2. **Контекстное меню.** В `TabContextMenu` добавить пункт «Показать в reference»
   вверху (рядом с pin). Прокинуть `onShowInReference` проп; вызывает
   `useReferenceStore.getState().linkTab(ctxMenu.id)`. Импортировать
   `useReferenceStore`. Размещение: первым блоком (как pin), либо в один блок с pin.

### ReferencePanel — `web/src/components/ReferencePanel/ReferencePanel.tsx`

Основная работа. Текущий компонент — база; scratch-ветку сохранить.

1. **Подписки:**
   ```ts
   const mode = useReferenceStore((s) => s.mode);
   const linkedTabId = useReferenceStore((s) => s.linkedTabId);
   const linkTab = useReferenceStore((s) => s.linkTab);
   const unlink = useReferenceStore((s) => s.unlink);
   // живое зеркало:
   const linkedTab = useEditorStore((s) =>
     mode === "tab" && linkedTabId ? s.tabs.find((t) => t.id === linkedTabId) ?? null : null
   );
   const tabs = useEditorStore((s) => s.tabs);   // для popover-списка
   ```
   `linkedTabClosed = mode === "tab" && linkedTabId !== null && linkedTab === null`.

2. **Шапка (header).** Заменить статичный лейбл «Reference» на **source-кнопку**:
   - scratch: показывает «Scratch».
   - tab + есть таб: показывает иконку-ссылку + `linkedTab.title` (truncate).
   - tab + закрыт: «Таб закрыт».
   Клик по кнопке → открыть **popover** (локальный `useState` `pickerOpen`).
   Рядом (только tab-режим, таб существует): **pencil-кнопка** → `focusLinkedTab()`.
   Справа — существующая close-кнопка.

3. **Searchable popover** (инлайн в этом файле, НЕ выносить — один call site, YAGNI):
   - `useState` для query.
   - Верхний пункт «Scratch (свободный текст)» → `unlink(); setPickerOpen(false)`.
   - Список `tabs.filter(t => t.title.toLowerCase().includes(query.toLowerCase()))`,
     по клику → `linkTab(t.id); setPickerOpen(false)`. Подсветить текущий `linkedTabId`.
   - Стиль — по образцу `web/src/components/TabSwitcher/TabSwitcher.tsx` (input +
     скроллируемый список, `max-h`). Закрытие по Escape / клику вне / выбору.

4. **Тело панели:**
   - `mode === "scratch"`: текущая редактируемая textarea (`value={text}` /
     `onChange={setText}`), без изменений.
   - `mode === "tab"` и таб существует: `readOnly` textarea
     `value={linkedTab.content}` (тот же стиль, но `readOnly`, можно чуть
     приглушить фон). Live-обновление обеспечено селектором.
   - `linkedTabClosed`: плейсхолдер по центру — текст «Таб закрыт» + кнопка
     «Вернуться к scratch» → `unlink()`.

5. **Кнопки (grid):**
   - «Вставить»: источник текста = `mode === "tab" ? (linkedTab?.content ?? "") : text`.
     Дальше существующая `insertIntoPrompt`-логика (вставка в активный таб по
     курсору). `disabled`, если источник пустой.
   - Вторая кнопка: scratch → «Очистить» (`clear`, как было);
     tab → «Отвязать» (`unlink`). В `linkedTabClosed` ряд кнопок можно скрыть
     (плейсхолдер уже даёт «Вернуться к scratch»).

6. **Pencil swap-хендлер:**
   ```ts
   function focusLinkedTab() {
     const { activeTabId, setActiveTab } = useEditorStore.getState();
     if (!linkedTabId) return;
     const prev = activeTabId;
     setActiveTab(linkedTabId);
     if (prev && prev !== linkedTabId) linkTab(prev);   // swap A/B
   }
   ```
   (Проверь имя экшена активации таба в editorStore — `setActiveTab`. Если иное —
   используй фактическое.)

7. **D&D drop-зона.** На корневом `<aside>`:
   ```ts
   onDragOver={(e) => {
     if (e.dataTransfer.types.includes("application/x-rewrite-tab-id")) {
       e.preventDefault();
       setDragOver(true);
     }
   }}
   onDragLeave={() => setDragOver(false)}
   onDrop={(e) => {
     const id = e.dataTransfer.getData("application/x-rewrite-tab-id");
     setDragOver(false);
     if (id) linkTab(id);
   }}
   ```
   `dragOver` (`useState`) → подсветка рамки/оверлея «Привязать таб». Resize-drag
   ручка (mouse-based) не конфликтует — это разные механизмы.

8. **Footer-хинт:** scratch → текущий текст; tab → «Зеркало таба (read-only).
   Карандаш — открыть на редактирование».

### Проверить — equality / ре-рендеры

- Селектор `linkedTab` возвращает объект таба — он меняет identity при каждом
  edit'е привязанного таба (именно это даёт live-обновление). Это ОК для
  reference panel (реактивный индикатор — не дебаунсить, см. CLAUDE.md). Не
  оборачивать в кастомный equality, иначе зеркало замёрзнет.

## Затрагиваемые файлы

```txt
web/src/store/referenceStore.ts                  # mode, linkedTabId, linkTab, unlink, hydrate
web/src/lib/db.ts                                # meta: referenceMode, referenceLinkedTabId
web/src/hooks/useSessionPersistence.ts           # прокинуть новые поля
web/src/components/ReferencePanel/ReferencePanel.tsx  # dual mode, popover, pencil swap, mirror, D&D drop
web/src/components/TabBar/TabBar.tsx              # dataTransfer tab.id + ctx-menu «Показать в reference»
```

Desktop/Tauri файлы — НЕ трогать. Schema-миграции НЕ вводить.

## Test plan (manual)

1. Открыть reference (`Ctrl+R`) → по умолчанию scratch, работает как раньше.
2. Шапка → popover → выбрать таб → панель показывает его контент (read-only).
3. Переключиться на привязанный таб, поправить текст → зеркало обновляется live.
4. Pencil → привязанный таб стал активным, панель теперь зеркалит прежний
   активный (A/B bounce). Pencil ещё раз → вернулись.
5. ПКМ по другому табу → «Показать в reference» → привязка сменилась.
6. Перетащить таб из tab-bar на панель → привязка сменилась, drop подсветился.
7. «Вставить» в tab-режиме → живой контент таба вставлен в активный промпт.
8. «Отвязать» → вернулись в scratch, scratch-текст на месте.
9. Закрыть привязанный таб (`Ctrl+W` на нём) → панель показывает «Таб закрыт» +
   «Вернуться к scratch».
10. Перезапуск приложения → mode/привязка восстановились (если таб жив).

Verification:
```bash
cd web && bun tsc --noEmit && bun lint
```

## Явные отказы

- НЕ делать editable split (правка привязанного таба прямо в панели). Только
  read-only + pencil-swap.
- НЕ выносить popover в отдельный shared-компонент (один call site).
- НЕ вводить schema-версию/миграцию (meta — key-value).
- НЕ трогать resize-ручку, тоггл `Ctrl+R`, scratch-логику (кроме переименования
  кнопки в tab-режиме).
- НЕ добавлять Tauri permissions.

## Definition of done

- Acceptance criteria checked.
- `cd web && bun tsc --noEmit && bun lint` — clean.
- Manual test plan пройден.
- Коммит на web feature-ветке `feature/reference-live-tab` (создавать **внутри**
  `web/`: `cd web && git switch -c feature/reference-live-tab`), русский
  Conventional Commit.
