# Rewrite Desktop

Нативная desktop-обёртка для [Rewrite](https://github.com/exviolet/rewrite) на базе Tauri v2.

## 🚀 Возможности

### 🖥️ Нативный опыт (Tauri)
- **Файловая система**: Нативные диалоги открытия, сохранения, а также экспорта и импорта ваших файлов.
- **Интерфейс**: Кастомный title bar с поддержкой стандартных элементов управления окном (window controls).
- **Уведомления**: Глобальные системные toast-уведомления о важных событиях.
- **Удобство**: Мгновенное восстановление случайно закрытых вкладок комбинацией `Ctrl+Shift+T`.

### 📝 Мощный редактор (Rewrite Web)
- **Мультизадачность**: Полноценная поддержка вкладок (табов) для одновременной работы с несколькими документами.
- **Продвинутый поиск**: Инструмент Find & Replace для массовой обработки текста.
- **Пресеты**: Поддержка пользовательских пресетов для быстрых замен.
- **Умная работа**: Интеграция с AI Prompt Builder для автоматизации задач.
- **Визуализация**: Встроенное превью Markdown в реальном времени.

## 🏗️ Архитектура проекта

Структура приложения разделена на два основных компонента, где веб-версия подключается как `git submodule`:

```text
rewrite-desktop/
├── web/                    # git submodule → rewrite (browser SPA)
├── src-tauri/
│   ├── src/
│   │   ├── lib.rs          # Tauri entry point
│   │   └── main.rs         # binary entry
│   ├── capabilities/
│   │   └── default.json    # Tauri v2 permissions
│   ├── icons/              # иконки приложения
│   ├── tauri.conf.json     # конфигурация Tauri
│   └── Cargo.toml
├── com.rewrite.app.desktop # .desktop файл для Linux
├── install.sh              # скрипт установки
├── uninstall.sh            # скрипт удаления
└── package.json
```

### 💡 Ключевые архитектурные решения
- **Разделение репозиториев**: Браузерный SPA-клиент не смешивается с Rust/Tauri кодом, десктопное приложение развивается независимо.
- **Submodule**: Фиксирует конкретную версию web-клиента — десктоп всегда собирается от проверенного, стабильного коммита.
- **Динамическая загрузка (Dynamic import)**: Все JS-пакеты Tauri загружаются только в десктопной среде (через проверку `isTauri`), поэтому браузерная версия остаётся легковесной.
- **Безрамочный интерфейс (Decorations: false)**: Системный title bar отключён, вместо него используется встроенный TabBar с drag-region и кнопками управления окном.
- **Безопасность (Минимальные права)**: Tauri имеет доступ только к чтению и записи текстовых файлов в базовых директориях пользователя (Desktop, Documents, Downloads, Temp). Нет доступа к сети или системным процессам.

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
