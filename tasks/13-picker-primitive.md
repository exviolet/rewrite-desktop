# Task 13 — Извлечение примитива модалки-пикера

**Status:** **active** (планировщик + исполнитель — Claude Opus)
**Issue:** [#9](https://github.com/exviolet/rewrite-desktop/issues/9)
**Owner:** Claude Opus (planner + executor)

> Рефакторинг 6 работающих модалок в daily-driver'е → **не big-bang**, поэтапно, каждый
> мигрированный пикер гоняется живьём. Форма примитива согласована с автором 2026-07-15.

## Цель

Пять (теперь шесть) компонентов — вариации **одного** паттерна «модалка-список: query +
фильтр + `↑↓` навигация + `Esc`/`Enter`»:

| Компонент | Строк | Особенность |
|---|---|---|
| `TabSwitcher` | 448 | preview-aside, multi-field fuzzy, `Tab`/`Ctrl+Del`, `pendingClose` |
| `GlobalSearchPanel` | 287 | группировка по табам + сниппет, `Aa`/`.*` тогглы, regex/case |
| `TmuxTargetPicker` | 248 | группировка по сессиям (плоский курсор сквозь секции), async |
| `CommandPalette` | 207 | fuzzy+score |
| `WorkspaceSwitcher` | 192 | create-row («+ Новый») |
| `OrcaTargetPicker` | 184 | async loading/error, preselect active |

Дубль ≈ 250–300 строк. Главный выигрыш не в строках, а в том, что баги навигации чинятся
в одном месте, а новая модалка становится тривиальной.

## Решения (залочены 2026-07-15)

- **Headless-хук + presentational-shell**, НЕ render-prop `<PickerModal items renderRow>`.
  Причина: grouping (Tmux/GlobalSearch — плоский курсор сквозь секции), preview-aside
  (TabSwitcher), create-row (Workspace), async (Orca/Tmux) разбили бы render-prop на
  необъятный prop-surface и всё равно не влезли бы. Хук не знает про layout → все эти
  вариации ему безразличны.
- **Хук владеет минимумом, консьюмер — максимумом.** Хук: `selectedIndex` + refs + 3
  эффекта (focus-on-mount, keynav, scroll-into-view). Консьюмер оставляет **своё**: `query`,
  фильтрацию, данные, когда сбрасывать выделение, рендер строк. Так фиделити максимальный,
  магии минимум (в т.ч. сохраняются причуды: Tmux НЕ сбрасывает selection на ввод; GlobalSearch
  сбрасывает по `query`+`case`+`regex`).
- **Единый селектор скролла — `data-picker-index`.** Заменяет три конвенции
  (`children[i]` / `[data-row-index]` / `[data-result-index]`). Работает и для плоских, и для
  сгруппированных списков (консьюмер клеит атрибут на каждую строку, курсор `cursor++` сквозь
  секции).
- **Чистые хелперы — отдельно и заранее** (Фаза A). `fuzzyMatch`/`highlightText` не про модалку.
- **TabSwitcher мигрирует ТОЛЬКО хром+навигацию.** Preview, scoring, спец-клавиши, `pendingClose`
  остаются bespoke. Если примитив где-то не ложится — **не форсим**, оставляем как есть (инвариант
  из issue #9).

## API

### `src/lib/fuzzyMatch.ts` (Фаза A)
Версия из `TabSwitcher` — надмножество (`-`/`_` word-boundary бонус + `baseScore`). `source`
НЕ входит в lib (это концерн консьюмера — TabSwitcher оборачивает и добавляет сам).
```ts
export interface FuzzyMatch { match: boolean; score: number; indices: number[]; }
export function fuzzyMatch(query: string, text: string, baseScore?: number): FuzzyMatch;
```
Замена в `CommandPalette` даёт ему `-`/`_` бонус — улучшение, не регресс.

### `src/lib/highlight.tsx` (Фаза A)
```ts
export function highlightMatches(text: string, indices: number[]): ReactNode; // пустые indices → сырой text
```
Гей-зона «lib = .ts»: это чистая функция, просто возвращает ReactNode. Ок в lib.

### `src/hooks/usePickerModal.ts` (Фаза B)
```ts
interface UsePickerModalOptions {
  count: number;                                   // длина плоского списка (вкл. create-row)
  onEnter: (index: number) => void;                // Enter по selectedIndex
  onClose: () => void;
  onKeyDown?: (e: KeyboardEvent) => boolean | void; // вызывается ПЕРВЫМ; true = handled, гасит дефолт-навигацию
  disabled?: boolean;                              // ранний return (TabSwitcher: pendingClose)
  initialIndex?: number;                           // ленивый старт (Workspace: active); useState-семантика (только первый рендер)
}
// → { selectedIndex, setSelectedIndex, inputRef, listRef }
```
- keydown в **capture-фазе** (`true`) — как сейчас. Порядок: `disabled` → `onKeyDown` →
  `Esc`/`↓`/`↑`/`Enter`.
- Консьюмер вешает `inputRef` на инпут, `listRef` на скролл-контейнер, клеит
  `data-picker-index={i}` на строки, сам зовёт `setSelectedIndex(0)` там, где сбрасывает
  сегодня.
- Async/preselect (Orca `.then`, Tmux rows-эффект) остаются у консьюмера — зовут
  `setSelectedIndex`, эффект отрабатывает после и «выигрывает».
- **Callbacks мемоизировать** (`onEnter`/`onKeyDown`) — иначе листенер пере-подписывается
  каждый рендер (как и сейчас в компонентах).

### `src/components/PickerModal/PickerModal.tsx` (Фаза B)
Хром + идентичный инпут-хедер + дефолтный футер. Хедер varies (icon vs label, тогглы, формат
счётчика) → prefix/suffix как ReactNode.
```tsx
<PickerModal onClose width? paddingTop? footer?>        // overlay+backdrop+панель+футер
<PickerHeader prefix suffix inputRef value onChange placeholder />  // дедуп идентичного инпута
```
`width`/`paddingTop` — inline-style (значения динамические: 560/640/900/980, 10/12/15vh).
Дефолтный футер: `↑↓ навигация · ↵ выбрать · Esc закрыть` (переопределяемо).

## Фазы (порядок из issue #9)

- **A — чистые хелперы.** `lib/fuzzyMatch.ts` + `lib/highlight.tsx`; перевести
  `CommandPalette` / `GlobalSearchPanel` / `TabSwitcher`. Отдельный коммит, риск ≈ 0.
- **B1 — примитив + простые.** `usePickerModal` + `<PickerModal>`; мигрировать
  `WorkspaceSwitcher` (create-row) и `OrcaTargetPicker` (async). Проверяем каркас на этих двух.
- **B2 — grouped.** `TmuxTargetPicker` + `GlobalSearchPanel` (плоский курсор сквозь секции через
  `data-picker-index`; Tmux — причуда «не сбрасывать selection на ввод», сохранить его rows-эффект).
- **B3 — TabSwitcher.** Только хром+навигация. Preview-aside / scoring / `Tab`/`Ctrl+Del` /
  `pendingClose` — bespoke (через `onKeyDown`/`disabled`/свой рендер). Не влезает — не форсим.

Каждая фаза — атомарный коммит на ветке `feature/picker-primitive` (в `web/`).

## Ловушки (из чтения кода 2026-07-15)

- **`CommandPalette` и `TabSwitcher` скроллят через `list.children[i]`** — сломается, если
  строки завернуть. Перевод на `data-picker-index` это чинит заодно.
- **`TmuxTargetPicker` НЕ делает `setSelectedIndex(0)` на ввод** (единственный) — полагается на
  rows-эффект с last-target. Не навязывать сброс.
- **`GlobalSearchPanel` сбрасывает выделение в эффекте** по `[query, caseSensitive, regex]`
  (set-state-in-effect, но линт зелёный) — сохранить как есть, хук в query не лезет.
- **`WorkspaceSwitcher` create-row**: `count = rows.length + 1`, `onEnter(createIndex)` создаёт.
- **`TabSwitcher`**: `pendingClose` гасит все клавиши (`disabled`); `Tab` (bound-only) и
  `Ctrl+Del` (close) — через `onKeyDown`, вернуть `true`. `Ctrl+Backspace` НЕ трогать (это
  «удалить слово» в инпуте).
- **Инвариант отправки промпта не в этом слое** — пикер лишь зовёт `onPick`; резолв/защита
  «не тому агенту» живут в `tmuxResolve.ts`/`useOrcaSend`. Рефактор пикера их не касается.

## Verification

Тестов в проекте нет (YAGNI). Гейт каждой фазы: `cd web && bun tsc -b && bun lint` = 0, затем
**живой прогон** мигрированных пикеров:
- базовое: открыть, набрать, `↑↓`, `Enter`, `Esc`, mouse-hover-select;
- Tmux — навигация `↓` через границы сессий (курсор не сбивается); preselect last-target;
- Workspace — `↓` до create-row, `Enter` создаёт; preselect active в switch-режиме;
- Orca/Tmux — loading/error/empty-состояния целы;
- TabSwitcher — `Tab` (tmux-фильтр), `Ctrl+Del` (закрыть), `Ctrl+Backspace` (удалить слово в
  инпуте, НЕ закрыть таб), preview-aside следует за выделением, `pendingClose` гасит клавиши.
