# Task 12 — Workspaces (изоляция табов + свитчер)

**Status:** **done** (спек и имплементация — Claude Opus; web `a924e90`, merge `feature/workspaces`)
**Priority:** #7 (см. [docs/ROADMAP.md](../docs/ROADMAP.md))
**Owner:** Claude Opus (planner + executor)

> Спек намеренно детальный (писался под возможную передачу Codex'у). Где упираешься
> в неясность — спроси, не угадывай.

> **Известный размен:** `WorkspaceSwitcher` станет **шестой** копией паттерна
> «модалка-пикер» ([#9](https://github.com/exviolet/rewrite-desktop/issues/9) — извлечение
> примитива сознательно отложено до после Workspaces). Поэтому писать его **строго по
> существующему паттерну** (`TmuxTargetPicker` / `OrcaTargetPicker`), не изобретая свой —
> чтобы будущее извлечение осталось механическим.

## Цель

Боль: проектные и личные табы теряются вместе, 75+ табов = шум. `Ctrl+T` решил
*переключение*, но не *пространство*.

Workspace = **изолированная группа табов**. Переключился → в TabBar видны только табы
этого workspace, остальные скрыты. Это НЕ knowledge base, НЕ хранилище, НЕ браузерные
группировки.

## Решения (грилл-сессия 2026-07-10, залочены)

- **Изоляция, не группировка.** Переключение workspace **фильтрует** TabBar. Браузерные
  сворачиваемые группы (всё видно) — **отклонены в v1**, запаркованы в
  [#4](https://github.com/exviolet/rewrite-desktop/issues/4). Не строим два org-механизма разом.
- **Один workspace на таб** (партиция, не теги).
- **Пины — по-workspace.** Закреплённый таб виден только в своём workspace.
- **UI переключения — только свитчер-модалка** (`Ctrl+Shift+W`). Сайдбар (постоянный /
  скрытый / hover) запаркован в [#7](https://github.com/exviolet/rewrite-desktop/issues/7);
  дропдаун в таб-баре отклонён.
- Новый таб создаётся **в активном workspace**. Перенос — контекстное меню + палитра.
- Каждый workspace помнит **свой last-active таб**.
- Существующие табы → workspace **«Default»** (additive `workspaceId`, БЕЗ деструктива:
  у 2-го юзера накоплены данные).
- **Ctrl+T (tab switcher) скоупится** активным workspace. **Ctrl+Shift+D (global search)
  остаётся кросс-workspace** — это осознанный escape hatch (имена совпадают со смыслом).

## Не в scope (не делать)

Сайдбар, браузерные группы, цвета/иконки workspace, DnD таба между workspace,
`Ctrl+1..9` для прыжка, welcome/onboarding, вложенность, «слои».

## Acceptance criteria

- [ ] `Workspace { id, name, createdAt, lastActiveTabId? }`; `Tab.workspaceId: string`.
- [ ] Инварианты держатся всегда: **≥1 workspace**; **есть активный workspace**; **у каждого
      таба есть `workspaceId`**; **активный таб принадлежит активному workspace**; **активный
      workspace содержит ≥1 таб**.
- [ ] `Ctrl+Shift+W` открывает свитчер workspace. `Ctrl+W` (без shift) по-прежнему закрывает таб.
- [ ] Свитчер: список workspace + счётчик табов, активный помечен, ввод = фильтр по имени,
      `Enter` = переключиться, есть строка «+ Новый workspace».
- [ ] Переключение workspace: TabBar показывает только его табы; активным становится его
      last-active таб (если жив), иначе первый; если табов нет — создаётся свежий.
- [ ] Пины: pinned-табы workspace идут левее обычных **внутри своего workspace**; пины чужих
      workspace не видны и не влияют.
- [ ] Bulk-операции скоупятся активным workspace: «закрыть остальные / сохранённые / справа»,
      cleanup пустых **не трогают чужие workspace**.
- [ ] Закрытие последнего таба активного workspace создаёт свежий таб **в нём же**.
- [ ] `Ctrl+Tab` / `Ctrl+Shift+Tab` циклят только по табам активного workspace.
- [ ] `Ctrl+T` (tab switcher) показывает только табы активного workspace.
- [ ] `Ctrl+Shift+D` (global search) ищет по **всем** workspace; выбор таба из другого
      workspace переключает workspace и активирует таб.
- [ ] `Ctrl+Shift+T` (reopen) возвращает последний закрытый таб **активного workspace**.
- [ ] Контекстное меню таба: «Переместить в workspace…» → пикер. Перенос сохраняет pin.
- [ ] Палитра команд: создать / переименовать / удалить workspace, переключиться, переместить таб.
- [ ] Удаление workspace: последний удалить **нельзя**; при наличии табов — `ConfirmDialog`,
      табы **переезжают** в первый оставшийся (никогда не удаляются молча).
- [ ] StatusBar показывает имя активного workspace.
- [ ] `ShortcutsModal`: добавлен `Ctrl+Shift+W`.
- [ ] Всё переживает рестарт (IndexedDB): workspaces, `workspaceId` табов, активный workspace,
      last-active таб каждого workspace.
- [ ] Старая база (без workspaces) поднимается: создаётся «Default», все табы получают его id.
      Ничего не теряется.
- [ ] `cd web && bun tsc -b && bun lint` — clean. (`-b`, НЕ `--noEmit`: корневой tsconfig —
      solution-stub, `--noEmit` проверяет 0 файлов.)

## Scope (точная реализация)

### 1. Данные — `web/src/store/editorStore.ts`

Workspaces живут **в `editorStore`**, а не в отдельном сторе. Причина: инварианты
(«активный таб ∈ активный workspace», «активный workspace непуст») связывают табы и
workspace в одной транзакции — разнесение по сторам породило бы cross-store гонки.

```ts
export interface Workspace {
  id: string;               // uuid
  name: string;
  createdAt: number;
  lastActiveTabId?: string; // обновляется в setActiveTab
}

export interface Tab {
  // …существующее
  workspaceId: string;      // обязателен ПОСЛЕ гидрации
}
```

Новое в сторе: `workspaces: Workspace[]`, `activeWorkspaceId: string`.

Новые экшены:
- `setActiveWorkspace(id)` — сохранить текущий `activeTabId` в `lastActiveTabId` уходящего
  workspace; переключить; выбрать таб: `lastActiveTabId` (если жив и принадлежит этому
  workspace) → иначе первый таб workspace → иначе создать свежий.
- `createWorkspace(name)` — uuid, push, переключиться на него, создать в нём свежий таб.
- `renameWorkspace(id, name)`.
- `deleteWorkspace(id)` — если он единственный → no-op (UI не должен давать). Табы переезжают
  в первый оставшийся (порядок сохраняется). Если удалялся активный → переключиться на первый
  оставшийся.
- `moveTabToWorkspace(tabId, workspaceId)` — меняет `workspaceId` таба (pin сохраняется). Если
  переезжал активный таб → в текущем workspace выбрать новый активный (или создать свежий,
  если опустел).

Правки существующих экшенов:
- `createTab`, `addTabFromFile` — присваивают `workspaceId: activeWorkspaceId`.
- `setActiveTab(id)` — **если таб принадлежит другому workspace, переключить и workspace тоже**
  (это то, за счёт чего global search работает без отдельного экшена). Обновляет
  `lastActiveTabId` активного workspace.
- `performClose` / `performCloseMany` — «остался 0 табов» проверяется **в пределах активного
  workspace**, свежий таб создаётся в нём.
- `closeSavedTabs`, `closeOtherTabs`, `closeTabsToRight`, `cleanupEmptyTabs` — фильтровать
  кандидатов по `workspaceId === activeWorkspaceId`. `closeTabsToRight` считает «правее» по
  **видимому** (отфильтрованному) списку.
- `reopenTab` — снимать со стека последний закрытый таб, у которого
  `workspaceId === activeWorkspaceId` (стек `closedTabs` остаётся глобальным). Если у таба
  workspace уже удалён — присвоить активный.
- `reorderTab` — **сменить сигнатуру на `reorderTab(fromId: string, toId: string)`.** Индексы
  из отфильтрованного TabBar не совпадают с глобальными; резолвить id → глобальные индексы
  внутри стора. Единственный call site — TabBar.
- `hydrate(tabs, activeTabId, tabCounter, workspaces, activeWorkspaceId)` — см. §3.

`partitionPinned` **менять не нужно.** Глобальная партиция + фильтр по workspace даёт верный
порядок: `filter` сохраняет относительный порядок, поэтому внутри каждого workspace pinned
остаются левее обычных.

Модульная инициализация (до гидрации): создать дефолтный workspace и `initialTab` в нём —
`const initialWs = { id: crypto.randomUUID(), name: "Default", createdAt: Date.now() }`.
`makeTab` в `lib/tabUtils.ts` получает второй аргумент `workspaceId`.

### 2. Чистые хелперы — `web/src/lib/tabUtils.ts`

- `makeTab(n: number, workspaceId: string): Tab`.
- `tabsOf(tabs: Tab[], workspaceId: string): Tab[]` — фильтр (использовать везде, где нужен
  видимый список).
- `normalizeTab` — оставить `...tab`, `workspaceId` присваивается в `hydrate`, не здесь.

### 3. Персистентность — `web/src/lib/db.ts`

- **DB v4 → v5.** В `upgrade`: `if (oldVersion < 5) db.createObjectStore("workspaces", { keyPath: "id" })`.
  Это **аддитивно** — существующие `tabs`/`presets`/`triggerPhrases` не трогаем, миграции данных нет.
- Схема `RewriteDB`: добавить стор `workspaces: { key: string; value: Workspace }`.
- `meta`: новые ключи `activeWorkspaceId` (string), `workspaceOrder` (string[]).
- `loadSession` — вернуть `workspaces` (упорядоченные по `workspaceOrder`, как `orderTabs`) и
  `activeWorkspaceId`.
- `saveSession` — принять и записать `workspaces`, `activeWorkspaceId`, `workspaceOrder`.
  Сигнатура уже длинная — **сгруппировать аргументы в объект**, а не добавлять 3 позиционных.

**Bootstrap старой базы (в `hydrate`, не в `db.ts`):** если `workspaces` пуст →
создать `{ id, name: "Default", createdAt: Date.now() }`; всем табам без `workspaceId` присвоить
его id; `activeWorkspaceId` = его id. Если `activeWorkspaceId` указывает на несуществующий
workspace → первый в списке.

### 4. Хоткеи — `web/src/hooks/useKeyboardShortcuts.ts`

- Новый колбэк `onWorkspaceSwitcher?: () => void` на `ctrl && e.shiftKey && code === "KeyW"`.
- **Ветку `ctrl && code === "KeyW"` (закрытие таба) дополнить `&& !e.shiftKey`.** Сейчас она
  ловит и `Ctrl+Shift+W` — то есть новый хоткей без этой правки будет закрывать таб.
  (Прочие ветки без shift-гарда — `KeyS`, `KeyN`, `KeyO`, `KeyM`, `KeyE`, `KeyH`, `KeyK` — в
  этой задаче **не трогать**, отдельная уборка.)
- Ветку `Ctrl+Tab` / `PageUp` / `PageDown`: циклить по `tabsOf(tabs, activeWorkspaceId)`,
  а не по всему `tabs`.

### 5. UI

**`web/src/components/WorkspaceSwitcher/WorkspaceSwitcher.tsx`** (новый) — зеркалить
`TabSwitcher.tsx` / `TmuxTargetPicker.tsx`:
- Проп `mode: "switch" | "move"`. `switch` — переключить workspace; `move` — выбрать целевой
  workspace для переноса таба (`onPick(workspaceId)`).
- Строки: имя + счётчик табов; активный помечен. Ввод = фильтр. `↑/↓` навигация, `Enter` выбор,
  `Esc` закрыть. В режиме `switch` — строка «+ Новый workspace» (создаёт по введённому имени).

**`TabBar.tsx`:**
- Рендерить `tabsOf(tabs, activeWorkspaceId)`.
- **`tabsMetaEqual` дополнить `tab.workspaceId`** — иначе при переключении workspace /
  переносе таба полоса «замерзает» (тот же класс бага, что был с `orcaBinding`).
- Подписаться на `activeWorkspaceId`.
- DnD: передавать в `reorderTab` **id**, а не индексы.
- Контекстное меню таба: пункт «Переместить в workspace…» → открыть свитчер в режиме `move`.

**`StatusBar.tsx`:** показать имя активного workspace (реактивно, **без дебаунса** — см.
CLAUDE.md Safety Rails).

**`TabSwitcher.tsx` (Ctrl+T):** список = `tabsOf(tabs, activeWorkspaceId)`.

**`GlobalSearchPanel.tsx` (Ctrl+Shift+D):** ищет по всем табам; в строке результата показать
имя workspace, если он не активный; выбор → `setActiveTab(id)` (тот сам переключит workspace).

**`useCommands.ts`:** команды `workspace: переключиться…`, `создать…`, `переименовать…`,
`удалить…`, `переместить таб в…`.

**`ShortcutsModal.tsx`:** строка `Ctrl+Shift+W` — свитчер workspace.

**Удаление:** `ConfirmDialog` — «Удалить workspace «X»? N табов переедут в «Y».» Кнопка удаления
недоступна, если workspace единственный.

### 6. Доки

- `docs/ROADMAP.md`: строка #7 → `done`/ссылка на этот файл после мержа.
- `web/CLAUDE.md`: секция «State Stores» — упомянуть workspaces в `editorStore`; «Persistence» —
  `rewrite-db` v5.

## Риски / на что смотреть

- **`tabsMetaEqual`** — самая вероятная тихая поломка (полоса не перерисуется).
- **Скоуп bulk-close** — если забыть фильтр, «закрыть сохранённые» молча убьёт табы чужих
  workspace. Инвариант «не разрушать молча» важнее удобства.
- **`reorderTab` по индексам** — при фильтрованном рендере индексы разъезжаются; отсюда смена
  сигнатуры на id.
- **Bootstrap старой базы** — у 2-го юзера 75+ табов; проверить, что после апдейта все на месте
  в «Default», ничего не потеряно. Это единственное место, где можно повредить чужие данные.
