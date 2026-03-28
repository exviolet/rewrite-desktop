# RewriteBox Desktop

Нативная desktop-обёртка для [RewriteBox](https://github.com/exviolet/rewritebox) на базе Tauri v2.

## Требования

- [Bun](https://bun.sh/) >= 1.0
- [Rust](https://rustup.rs/) stable
- Системные зависимости Tauri:
  - **Arch Linux**: `webkit2gtk-4.1`, `gtk3`, `libsoup3`
  - **Ubuntu/Debian**: `libwebkit2gtk-4.1-dev`, `libgtk-3-dev`, `libsoup-3.0-dev`

## Установка

```bash
git clone --recurse-submodules git@github.com:exviolet/rewritebox-desktop.git
cd rewritebox-desktop
bun install
```

## Разработка

```bash
bun dev       # Vite dev server + Tauri window
```

## Сборка

```bash
bun build     # Production build
```

## Обновление web

```bash
bun update-web    # Обновить submodule до последней версии
git add web
git commit -m "chore: обновлён web submodule"
```

## Лицензия

MIT
