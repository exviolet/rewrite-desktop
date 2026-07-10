<div align="center">

<img src="icon.svg" alt="Rewrite Desktop" width="112" height="112" />

# Rewrite Desktop

**Нативная desktop-обёртка для [Rewrite](https://github.com/exviolet/rewrite) на Tauri v2.**

<img src="https://img.shields.io/badge/license-MIT-8b5cf6?style=for-the-badge" alt="License MIT" />
<img src="https://img.shields.io/badge/platform-Linux-c4b5fd?style=for-the-badge" alt="Platform: Linux" />
<img src="https://img.shields.io/badge/status-personal_project-2a2650?style=for-the-badge" alt="Status: personal project" />

[English](README.md) · Русский

</div>

Этот репозиторий — тонкая нативная оболочка вокруг веб-приложения
[Rewrite](https://github.com/exviolet/rewrite) (подключено сюда как git-сабмодуль).
Что такое Rewrite — prompt-first workflow, возможности, скриншоты — смотри в
[**web README**](https://github.com/exviolet/rewrite/blob/master/README.ru.md).
Этот файл описывает только сборку и установку нативного бинарника.

## Что добавляет обёртка

- Нативные файловые диалоги (открытие / сохранение / импорт / экспорт).
- Кастомный title bar с window controls.
- Восстановление закрытых табов (`Ctrl+Shift+T`).
- Глобальные toast-уведомления.
- `tmux`-интеграция через `tauri-plugin-shell` — отправка (`Ctrl+Enter`), target
  picker (`Ctrl+Shift+Enter`) и привязка таба к окну. Основная причина
  существования desktop-сборки.

Всё остальное — полный набор возможностей браузерной версии.

## Требования

- [Bun](https://bun.sh/) ≥ 1.0
- [Rust](https://rustup.rs/) (stable)
- Системные зависимости Tauri (Linux):
  - **Arch**: `webkit2gtk-4.1`, `gtk3`, `libsoup3`
  - **Ubuntu/Debian**: `libwebkit2gtk-4.1-dev`, `libgtk-3-dev`, `libsoup-3.0-dev`

> Только Linux — намеренно. Без Windows/macOS-билдов, без auto-update.

## Установка

```bash
git clone --recurse-submodules https://github.com/exviolet/rewrite-desktop.git
cd rewrite-desktop
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

`build:bin` пропускает бандлинг AppImage/deb (он опирается на `linuxdeploy` и не
нужен для установки в `~/.local/bin`). Полный `bun run build` на части машин
падает на `linuxdeploy` — для установки он не требуется.

После `install.sh` приложение появляется в rofi / app launcher.

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

## Лицензия

MIT
