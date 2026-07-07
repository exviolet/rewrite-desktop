# Project Contract — Rewrite Desktop

> Этот файл — контракт сотрудничества между разработчиком и любым AI-агентом (Claude Code, Codex, Cursor, Aider). `AGENTS.md` — symlink сюда. Долгоживущие решения и roadmap живут в `docs/`, не в этом файле.

## Product Positioning
- **Rewrite — prompt-first editor.** Цель: быстро формулировать LLM-промпты вне маленького input в Claude Code и неудобного scroll в tmux.
- Не pipeline-builder, не knowledge base, не code editor.
- При любой новой фиче — сверять с позиционированием и приоритетом в [docs/ROADMAP.md](docs/ROADMAP.md). Pipeline/transformation-направление = red flag scope creep.

## Project Goals (приоритет)
> Пересмотрено 2026-07-07: курс на staged public OSS. Детали — docs/ROADMAP.md «Сессия 2026-07-07».
- **Primary:** личный инструмент + опыт работы с Tauri/Rust.
- **Primary:** **staged public OSS** — вести как настоящий открытый проект (стадии A презентабельность → B release-артефакты → C discoverability), честный scope, без обещаний enterprise-поддержки.
- **Secondary:** портфолио.

Следствия для решений: breaking changes без миграций всё ещё ок (ранняя стадия), но разрушающие data-изменения координировать со 2-м пользователем; для OSS-стадий **теперь оправданы** README+демо, лицензия, prebuilt release-артефакты, фикс дистрибуции (`--no-bundle` + `update.sh`), опц. CI (YAGNI-режим → нейтральный); без явного жильца по-прежнему НЕ делать Windows/macOS билды, i18n, CONTRIBUTING.md; «полировать для юзеров» vs «Tauri-эксперимент» — теперь баланс (есть внешние пользователи), не автоматически второе.

## Context
- **Solo dev, ранняя стадия (v0.1.0), 2 пользователя** (автор + друг — начал пользоваться сам, 2026-07). Курс на staged OSS. Миграции данных, feature flags, backwards-compat shims **не нужны** — clean sweeps допустимы, но разрушающие data-изменения (IndexedDB) координировать с другом (у него накоплены данные).
- GUI прошёл dogfooding: ежедневное использование, 75+ табов накопилось. Это значит UX-боль реальна, но не блокирует.

## Repo Layout
- `web/` — git submodule [exviolet/rewrite] (browser SPA, React + Zustand + Vite).
- `src-tauri/src/lib.rs` — точка входа Tauri v2 wrapper.
- `src-tauri/capabilities/default.json` — permission manifest.
- `src-tauri/tauri.conf.json` — Tauri-конфиг.
- `install.sh` / `uninstall.sh` — установка/удаление бинарника в `~/.local/` (Linux only).
- `docs/ROADMAP.md` — позиционирование, приоритеты, отказы. Источник правды по продуктовым решениям.
- `tasks/` — детальные task-спеки для приоритетных фич (создаются по мере того, как фича становится active).
- `HANDOFF.md` — per-session state (в `.gitignore`).
- `AGENTS.md` — symlink на этот файл (для codex/aider/cursor agent).

## Build & Test
- Install deps: `bun install`
- Dev: `bun dev` (Vite + Tauri window)
- Build production: `bun run build`
- Update web submodule: `bun update-web`
- Install / remove binary: `./install.sh` / `./uninstall.sh`

## Verification
| Изменения в | Команды |
|---|---|
| `web/src/**/*.ts(x)` | `cd web && bun tsc -b && bun lint` (НЕ `--noEmit`: корневой tsconfig — solution-stub с `files:[]`, `--noEmit` проверяет 0 файлов и всегда зелёный; реальный гейт — `-b`) |
| `src-tauri/src/**/*.rs` | `cd src-tauri && cargo check` |
| `src-tauri/capabilities/*.json`, `tauri.conf.json` | `bun run build` (валидация Tauri-манифеста) |
| указатель submodule обновлён | `git submodule status` должен быть чистый |

## Git Workflow (GitHub Flow)
- Базовая ветка: `master`. Без Git-Flow — нет `dev`, нет `release/*`.
- Новые фичи: `git switch -c feature/<name>` от `master`.
- Хотфиксы: `git switch -c fix/<name>` от `master`.
- Merge в `master` всегда `--no-ff` — границы фич видны в истории.
- Коммиты: атомарные, русские, Conventional Commits (`feat(scope): описание`).
- `git switch` вместо `git checkout`.

## Submodule Order
Изменения в `web/`:
1. Сначала коммит **внутри** `web/` и push submodule.
2. Возврат в desktop: `git add web && git commit -m "chore(web): обновлён указатель submodule"`.
3. Push desktop.

Никогда не обновлять указатель submodule в desktop до коммита в `web/` — иначе указатель ссылается на dangling commit.

## Safety Rails

### NEVER
- Не добавлять Tauri permissions в `src-tauri/capabilities/default.json` без явного подтверждения. Модель: **редактор держит границу no-network-egress** — webview не делает произвольных сетевых вызовов и не спавнит произвольные процессы. (Реформулировано 2026-07-07: это НЕ «local-first как продуктовая догма» — сетевое/AI живёт в отдельном companion-продукте за opt-in границей, не в редакторе. Причина границы: `fs:scope-home-recursive` + сетевой egress = поверхность утечки; `web/` тянется submodule'ом, не аудируется построчно.) Исключения через `tauri-plugin-shell`:
  - `tmux` — отправка текста в выбранную pane + чтение топологии read-only (`list-panes`/`list-windows`/`list-sessions` для target picker'а). Заскоуплен `args:true`.
  - `orca-ide` (Orca ADE CLI) — **Policy B, scoped по подкомандам (НЕ `args:true`)**: только `terminal send` (отправка промпта), `terminal list` / `worktree ps` (read-only топология + `lastAssistantMessage`), `terminal wait --for tui-idle` (settle/refresh). Явно НЕ разрешены: `computer` (управление десктопом), `terminal create --command` (спавн процессов), `worktree create/rm`, browser/automations — поверхность `orca-ide` качественно опаснее tmux, `args:true` молча выдал бы desktop-control + произвольные процессы. Подтверждено 2026-07-01.
  - Остальной shell, сеть и произвольные процессы не разрешены.
  - NB: `fs`-read/write в home-scope **уже выдан** в манифесте (`fs:scope-home-recursive` + `allow-write-text-file`) — оговорка «без доступа к процессам» относится к shell/сети, не к fs.
- Не делать `git push --force` на `master`.
- Не запускать `./uninstall.sh` без подтверждения (стирает установленный бинарник).
- Не коммитить `HANDOFF.md`.
- Не обновлять указатель submodule в desktop до коммита в `web/`.
- Не вводить миграции данных, feature flags, backwards-compat shims.

### ALWAYS
- Перед merge в `master` — прогнать relevant verification из таблицы выше.
- В конце сессии — обновить `HANDOFF.md` (текущий статус, незакоммиченное, next steps, открытые риски). Это правило применимо к Claude Code сессиям; codex-сессии могут пропускать.
- При предложении новой фичи — сверить с приоритетом в [docs/ROADMAP.md](docs/ROADMAP.md). Не предлагать фичи из «Отложено».
- Реактивные UI-индикаторы (StatusBar, dirty-индикаторы и подобное) — **не дебаунсить**. Задержка >0 раздражает сильнее любой невидимой перф-выгоды. Оптимизировать только невидимое (custom equality в Zustand-селекторах, RAF debounce на тяжёлых операциях).

## Roles (multi-agent workflow)

Проект используется в режиме «архитектор + исполнитель»:

- **Claude Opus (architect)** — планирование, грилл-сессии, принятие архитектурных решений, финальные коммиты, обновление `docs/ROADMAP.md` и `tasks/*.md`.
- **Codex (executor)** — имплементация задач из `tasks/*.md` по детальному спеку. Не принимает решений вне спека; если упирается в неясность — оставляет TODO/комментарий, не угадывает.

Если запущены параллельно в tmux — оба видят `CLAUDE.md` (= `AGENTS.md`), `docs/ROADMAP.md`, `tasks/`, `HANDOFF.md`. Memory (`~/.claude/projects/...`) — только Claude Code, codex её не читает.

## Compact Instructions
При сжатии контекста сохранить:
- Текущая фича из `tasks/` и её статус.
- Принятые архитектурные решения и явные отказы (см. `docs/ROADMAP.md` секция «Явные отказы»).
- Verification-статус: что прошло, что упало, что не запускалось.
- Незакоммиченные файлы и текущая ветка.
- Открытые риски и TODO.
