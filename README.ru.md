<div align="center">

<img src="icon.svg" alt="Sendoff Desktop" width="112" height="112" />

# Sendoff Desktop

**Нативная desktop-обёртка для [Sendoff](https://github.com/exviolet/sendoff-web) на Tauri v2.**

<img src="https://img.shields.io/badge/license-MIT-8b5cf6?style=for-the-badge" alt="License MIT" />
<img src="https://img.shields.io/badge/platform-Linux-c4b5fd?style=for-the-badge" alt="Platform: Linux" />
<img src="https://img.shields.io/badge/status-personal_project-2a2650?style=for-the-badge" alt="Status: personal project" />

[English](README.md) · Русский

</div>

Этот репозиторий — тонкая нативная оболочка вокруг веб-приложения
[Sendoff](https://github.com/exviolet/sendoff-web) (подключено сюда как git-сабмодуль).
Что такое Sendoff — prompt-first workflow, возможности, скриншоты — смотри в
[**web README**](https://github.com/exviolet/sendoff-web/blob/master/README.ru.md).
Этот файл описывает только сборку и установку нативного бинарника.

## Что добавляет обёртка

- Нативные файловые диалоги (открытие / сохранение / импорт / экспорт).
- Кастомный title bar с window controls.
- Восстановление закрытых табов (`Ctrl+Shift+T`).
- Глобальные toast-уведомления.
- `tmux`-интеграция через `tauri-plugin-shell` — отправка (`Ctrl+Enter`), target
  picker (`Ctrl+Shift+Enter`) и привязка таба к окну. Основная причина
  существования desktop-сборки.
- Интеграция с [Orca ADE](https://github.com/stablyai/orca) — привязываешь таб к
  Orca-агенту, и `Ctrl+Enter` отправляет промпт в терминал этого агента вместо
  tmux-панели.
- Интеграция с [Herdr](https://herdr.dev) — то же самое для панели Herdr-агента.
  Herdr персистит id панелей, поэтому, в отличие от tmux и Orca, привязка
  переживает рестарт сервера и ребут. **Нужен Herdr ≥ 0.7:** после 0.6 сменился
  вид id панелей (`w657cefe818690a-1` → `wK:p1`), и старую форму отклоняет
  allowlist команд — отправка падает с сообщением, которое винит разрешение, а не
  версию.
- Единый пикер целей на все три источника (`Ctrl+Shift+Enter`) с секциями;
  незапущенный источник просто не даёт секции.
- Живой статус агента в status bar — тихая точка, пока агент работает, и заметная
  подпись, только когда он остановился и ждёт твоего ответа.
- Работает ровно один инстанс: повторный запуск сразу завершается и второго окна
  не открывает. Две копии на одной базе тихо съедали бы работу друг друга —
  запись идёт снапшотом целиком, поэтому отставший инстанс затирает то, что
  успел создать первый. Поднять уже открытое окно повторный запуск пытается, но
  Wayland-композиторы игнорируют запрос активации от процесса, с которым
  пользователь только что не взаимодействовал, — визуально не происходит ничего.
  Замерено на niri, одинаково у AppImage и у сборки из исходников.

Всё остальное — полный набор возможностей браузерной версии.

## Разрешения

У webview намеренно узкая shell-поверхность: `tmux`, а также `orca-ide` и
`herdr`, заскоупленные отдельными подкомандами на чтение/отправку. Для `herdr`
скоуп особенно важен: тот же бинарь умеет запускать произвольные процессы и
гасить сессии, поэтому разрешены только конкретные подкоманды, а не бинарь
целиком. Ни произвольных процессов, ни сетевых вызовов из редактора — доступ к файлам в home безопасен именно поэтому.
См. `src-tauri/capabilities/default.json`.

## Скачать

Бери AppImage из [последнего релиза](https://github.com/exviolet/sendoff/releases/latest):

```bash
chmod +x Sendoff_*_amd64.AppImage
./Sendoff_*_amd64.AppImage
```

Нужен **glibc ≥ 2.35** — Ubuntu 22.04+, Debian 12+, Fedora 36+, Arch. Собирается
в контейнере на Ubuntu 22.04 именно поэтому: AppImage бандлит библиотеки, но
**не** glibc, так что сборка на rolling-дистрибутиве дала бы файл, работающий
только на rolling-дистрибутивах.

Ждёт от системы обычный десктопный набор — те библиотеки, которые AppImage
намеренно не бандлит (X11/Wayland, OpenGL, fontconfig, freetype). На любом
десктопе они есть, в голом контейнере — нет.

> ⚠️ **Не смешивай AppImage со сборкой из исходников на одной машине.** Обе
> используют один каталог данных, но AppImage несёт WebKitGTK 2.50, а свежий
> дистрибутив даёт 2.52+. Начиная с 2.52 WebKit пишет IndexedDB в новом формате
> метаданных и **молча повышает базу при первом же открытии**, после чего AppImage
> прочитать её больше не может — покажет пустой редактор и ошибку про storage.
> Данные при этом целы и не перезаписываются: не сумев прочитать, Sendoff вообще
> перестаёт писать. Лечится возвратом на ту сборку, которой пользовался раньше.
> Направление одностороннее: новый WebKit старую базу читает, старый новую — нет.

Auto-update нет: чтобы обновиться, скачай новый AppImage либо собирай из
исходников и пользуйся `./update.sh`.

## Требования (для сборки из исходников)

- [Bun](https://bun.sh/) ≥ 1.0
- [Rust](https://rustup.rs/) (stable)
- Системные зависимости Tauri (Linux):
  - **Arch**: `webkit2gtk-4.1`, `gtk3`, `libsoup3`
  - **Ubuntu/Debian**: `libwebkit2gtk-4.1-dev`, `libgtk-3-dev`, `libsoup-3.0-dev`

> Только Linux — намеренно. Без Windows/macOS-билдов, без auto-update.

## Установка

```bash
git clone --recurse-submodules https://github.com/exviolet/sendoff.git
cd sendoff-desktop
bun install
```

## Разработка

```bash
bun dev      # Vite dev server + окно Tauri
```

## Сборка и установка

```bash
bun run build:bin   # собрать только бинарник (tauri build --no-bundle)
./install.sh        # установить в ~/.local/ (бинарник + .desktop + иконка)
./uninstall.sh      # удалить
```

`build:bin` пропускает бандлинг AppImage/deb/rpm — для установки в
`~/.local/bin` они не нужны. Полный `bun run build` собирает все три.

После `install.sh` приложение появляется в rofi / app launcher.

### Release-артефакты

Релизные AppImage собираются в контейнере, чтобы остаться пригодными на старых
дистрибутивах (почему — см. [Скачать](#скачать)):

```bash
docker build -t sendoff-appimage-builder .
docker run --rm -v "$PWD":/src -u "$(id -u):$(id -g)" -e HOME=/tmp \
  -e CARGO_TARGET_DIR=/src/src-tauri/target-docker \
  sendoff-appimage-builder bash -lc 'bun install && bun run build'
```

Артефакт кладётся в `src-tauri/target-docker/release/bundle/appimage/`.
Публикуется только AppImage: `.deb` и `.rpm` выходят из той же сборки, но их
никто не ставил на Debian или Fedora, а выкладывать непроверенные пакеты —
обещание, которое проект не может обеспечить.

## Обновление установленной копии

```bash
./update.sh   # git pull + синхронизация web-сабмодуля + build:bin + install
```

Одной командой: тянет `master`, выставляет закоммиченный указатель `web/`,
пересобирает бинарник и переустанавливает. После — перезапусти приложение из лаунчера.

## Обновление web-сабмодуля (dev)

```bash
bun update-web                                       # подтянуть последний коммит web/
git add web && git commit -m "chore: обновлён web submodule"
```

## Статус

Личный инструмент на `v0.1.x`, ежедневное использование на Linux. Публичный как
портфолио — **работает для меня, но поддержка и стабильность не гарантируются.**

Честный scope: только Linux, только x86_64, без auto-update, issues могут висеть.
Тесты покрывают лишь чистую логику и слой IndexedDB. Контрибуции не
запрашиваются — форкай свободно.

## Лицензия

[MIT](LICENSE)
