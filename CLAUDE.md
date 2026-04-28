# Project Contract — Rewrite Desktop

> Этот файл — контракт сотрудничества между разработчиком и любым AI-агентом (Claude Code, Codex, Cursor, Aider). `AGENTS.md` — symlink сюда. Долгоживущие решения и roadmap живут в `docs/`, не в этом файле.

## Product Positioning
- **Rewrite — prompt-first editor.** Цель: быстро формулировать LLM-промпты вне маленького input в Claude Code и неудобного scroll в tmux.
- Не pipeline-builder, не knowledge base, не code editor.
- При любой новой фиче — сверять с позиционированием и приоритетом в [docs/ROADMAP.md](docs/ROADMAP.md). Pipeline/transformation-направление = red flag scope creep.

## Project Goals (приоритет)
- **Primary:** личный инструмент + опыт работы с Tauri/Rust.
- **Secondary:** портфолио.
- **Не цель:** OSS-продукт с поддержкой. Модель распространения — public repo, лицензия, README с дисклеймером «works for me, no support guaranteed».

Следствия для решений: предлагать быстрые breaking changes без миграций; не предлагать auto-update / CI-релизы / Windows билды / i18n / CONTRIBUTING.md; при выборе «полировать для юзеров» vs «экспериментировать с Tauri» — выбирать второе.

## Context
- **Solo dev, ранняя стадия (v0.1.0).** Один разработчик и один пользователь. Миграции данных, feature flags, backwards-compat shims **не нужны** — clean sweeps допустимы.
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
| `web/src/**/*.ts(x)` | `cd web && bun tsc --noEmit && bun lint` |
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
- Не добавлять Tauri permissions в `src-tauri/capabilities/default.json` без явного подтверждения. Модель: local-first, без доступа к сети и процессам. Исключение: `tmux` разрешён через `tauri-plugin-shell` только для отправки текста в выбранную pane; остальной shell, сеть и произвольные процессы не разрешены.
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
