# Rewrite Desktop

Нативная desktop-обёртка для [Rewrite](https://github.com/exviolet/rewrite) на базе Tauri v2.

## Возможности

- Нативные файловые диалоги (открытие, сохранение, экспорт/импорт)
- Кастомный title bar с window controls
- Восстановление закрытых табов (Ctrl+Shift+T)
- Глобальные toast-уведомления
- Все возможности браузерной версии: табы, Find & Replace, пресеты замен, AI Prompt Builder, Markdown превью

## Требования

- [Bun](https://bun.sh/) >= 1.0
- [Rust](https://rustup.rs/) stable
- Системные зависимости Tauri:
  - **Arch Linux**: `webkit2gtk-4.1`, `gtk3`, `libsoup3`
  - **Ubuntu/Debian**: `libwebkit2gtk-4.1-dev`, `libgtk-3-dev`, `libsoup-3.0-dev`

## Установка

```bash
git clone --recurse-submodules git@github.com:exviolet/rewrite-desktop.git
cd rewrite-desktop
bun install
```

## Разработка

```bash
bun dev       # Vite dev server + Tauri window
```

## Сборка и установка

```bash
bun run build     # Production build
./install.sh      # Установить в ~/.local/ (бинарник + .desktop + иконка)
```

После установки приложение доступно из rofi/app launcher.

```bash
./uninstall.sh    # Удалить
```

## Обновление web

```bash
bun update-web    # Обновить submodule до последней версии
git add web
git commit -m "chore: обновлён web submodule"
```

## Лицензия

MIT
