# Task 13 — Извлечение примитива модалки-пикера

**Status:** **done** — все фазы + CommandPalette (web merge `8257c7e`, ветка удалена)
**Issue:** [#9](https://github.com/exviolet/sendoff/issues/9)
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
  // вызывается ПЕРВЫМ; true = handled, гасит дефолт-навигацию. ctx = { index, setIndex } —
  // выделение аргументом, а не замыканием (иначе цикл: клавиши объявляются до вызова хука)
  onKeyDown?: (e: KeyboardEvent, ctx: PickerKeyContext) => boolean | void;
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

- **A — чистые хелперы.** ✅ **DONE** (web `06c832b`). `lib/fuzzyMatch.ts` + `lib/highlight.tsx`;
  `CommandPalette` / `GlobalSearchPanel` / `TabSwitcher` переведены. `tsc`+`lint` = 0.
- **B1 — примитив + простые.** ✅ **DONE** (web `abf8365`). `usePickerModal` + `<PickerModal>`
  (+`PickerHeader`/`PickerHint`); `WorkspaceSwitcher` (create-row) и `OrcaTargetPicker` (async)
  мигрированы. Живьём (bun dev + chrome-devtools): create-row+преселект+arrow-nav+switch+изоляция,
  Orca error-state, Esc/focus, Phase-A highlight — ок, консоль чистая.
- **B2 — grouped.** ✅ **DONE** (web `402b7d5`). `TmuxTargetPicker` + `GlobalSearchPanel`: плоский
  курсор сквозь секции через `data-picker-index`. Причуды сохранены — Tmux не сбрасывает выделение
  на ввод (им правит только rows-эффект с преселектом last-target), GlobalSearch сбрасывает
  эффектом по `query`/`case`/`regex`.
- **B3 — TabSwitcher.** ✅ **DONE** (web `742b4a4`). Только хром+навигация; preview-aside, scoring,
  `Tab`, `Ctrl+Del`, `pendingClose` остались bespoke. Потребовало правки примитива: `onKeyDown`
  получил 2-й аргумент `{ index, setIndex }` — иначе зависимость закольцовывалась (клавиши
  консьюмера объявляются до вызова хука, а выделением владеет хук).
- **CommandPalette.** ✅ **DONE** (web `07f5064`). В фазах поимённо не значился, но в «Ловушках»
  ниже прописан его перевод со `list.children[i]` — иначе одна из шести копий осталась бы старой.
  Дефолтный футер примитива подошёл без переопределения.

Каждая фаза — атомарный коммит на ветке `feature/picker-primitive` (в `web/`), merge `--no-ff`.

## Найдено по ходу: 7-я копия паттерна (НЕ мигрирована)

`TriggerPhrasePicker` (`Ctrl+K`, 190 строк) — тот же паттерн в режиме `list`, но модалка
двухрежимная: в `edit`/`new` она форма, где `Enter`/стрелки должны оставаться нативными
(ввод в textarea), а `Esc` двухуровневый (edit → назад в list, list → закрыть). Механической
миграции не выйдет: нужен `onKeyDown` с перехватом `Esc` при `mode !== "list"`.

Спек его не обследовал и в шести не считал — **решение по нему за автором**. Стоимость: ~30 строк
в консьюмере, риск низкий (тот же класс, что TabSwitcher).

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

**Итог 2026-07-27:** `tsc -b` + `lint` = 0 на всех этапах. Живой прогон — в **Tauri-сборке**
(`bun dev` + MCP-мост), т.е. с настоящей tmux-топологией (5 сессий, 17 pane) и реальной БД,
а не в браузере. Консоль чистая.

Проверено вживую: GlobalSearch — 18 совпадений в 3 секциях, курсор сквозь границы, клампы,
доскролл, `Enter` открывает таб + подсвечивает совпадение оверлеем; Tmux — курсор сквозь 4
границы сессий, `Enter` привязал/отправил **ровно в строку под курсором** (`%18` на плоском
индексе 8 — маппинг курсор→`rows` верен), преселект last-target и «ввод не сбрасывает выделение»
(после фильтра выделение уехало за `%18` на его новый индекс, а не в 0); TabSwitcher — preview-aside
следует за выделением, `Tab` (2/2 + смена плейсхолдера), `Ctrl+Del` → `pendingClose` → **стрелки
мертвы** (`disabled`) → подтверждение закрыло таб и индекс пересчитался, `Ctrl+Backspace` таб НЕ
закрыл; CommandPalette — 40 команд, ширина 448px как была, доскролл на индексе 20, `Enter`
выполняет; Workspace/Orca (B1) — открытие, фокус, async error-state целы.

Не проверено: нативное «удалить слово» по `Ctrl+Backspace` — WebDriver не доставляет нажатия с
модификаторами в этот webview. Важное (пикер его не перехватывает, таб цел) подтверждено.

Тестов в проекте нет (YAGNI). Гейт каждой фазы: `cd web && bun tsc -b && bun lint` = 0, затем
**живой прогон** мигрированных пикеров:
- базовое: открыть, набрать, `↑↓`, `Enter`, `Esc`, mouse-hover-select;
- Tmux — навигация `↓` через границы сессий (курсор не сбивается); preselect last-target;
- Workspace — `↓` до create-row, `Enter` создаёт; preselect active в switch-режиме;
- Orca/Tmux — loading/error/empty-состояния целы;
- TabSwitcher — `Tab` (tmux-фильтр), `Ctrl+Del` (закрыть), `Ctrl+Backspace` (удалить слово в
  инпуте, НЕ закрыть таб), preview-aside следует за выделением, `pendingClose` гасит клавиши.
