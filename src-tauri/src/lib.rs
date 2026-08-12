use tauri::Manager;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
  // WebKitGTK (Linux): DMABUF-рендерер даёт tearing/артефакты при скролле на части
  // GPU-драйверов (Nvidia, отдельные Mesa/Wayland). Отключаем глючный путь шаринга
  // буферов — аппаратный композитинг при этом остаётся. Ставим до создания webview.
  // Уважаем явный override: если переменная уже задана в окружении — не трогаем.
  #[cfg(target_os = "linux")]
  if std::env::var_os("WEBKIT_DISABLE_DMABUF_RENDERER").is_none() {
    std::env::set_var("WEBKIT_DISABLE_DMABUF_RENDERER", "1");
  }

  // GUI-запуск (.desktop/лаунчер) наследует урезанный PATH без ~/.local/bin,
  // где лежит orca-ide → tauri-plugin-shell не находит бинарь и orca-send
  // молча отваливается (в `bun run dev` PATH шелла богатый, потому работает).
  // Дотягиваем ~/.local/bin в начало PATH процесса до старта плагинов.
  #[cfg(target_os = "linux")]
  if let Some(home) = std::env::var_os("HOME") {
    let local_bin = std::path::Path::new(&home).join(".local/bin");
    let path = std::env::var_os("PATH").unwrap_or_default();
    if !std::env::split_paths(&path).any(|p| p == local_bin) {
      let mut paths = vec![local_bin];
      paths.extend(std::env::split_paths(&path));
      if let Ok(joined) = std::env::join_paths(paths) {
        std::env::set_var("PATH", joined);
      }
    }
  }

  // Переезд каталога данных после переименования проекта (Rewrite → Sendoff, 2026-08-13).
  // Каталог задаётся identifier'ом, поэтому у обновившегося пользователя данные остались
  // бы лежать под старым именем, а приложение завело бы ПУСТУЮ базу — снаружи это
  // неотличимо от потери данных, причём молча: баннер StorageError сюда не приходит,
  // потому что чтение не падает, читать просто нечего.
  //
  // install.sh делает ровно то же, но до него доходят только собирающие из исходников —
  // пользователь AppImage не запускает его никогда. Это перенос пути, а не миграция
  // схемы: база и её версия те же самые (DB_NAME намеренно остался "rewrite-db").
  //
  // Идёт до старта плагинов и webview. Гонка двух запусков безопасна: rename атомарен,
  // проигравший не пройдёт проверку на существование источника.
  #[cfg(target_os = "linux")]
  {
    let base = std::env::var_os("XDG_DATA_HOME")
      .map(std::path::PathBuf::from)
      .filter(|p| p.is_absolute())
      .or_else(|| {
        std::env::var_os("HOME").map(|h| std::path::Path::new(&h).join(".local/share"))
      });
    if let Some(base) = base {
      let old = base.join("com.rewrite.app");
      let new = base.join("dev.sendoff.app");
      // Только когда старый каталог есть, а нового ещё нет. Если новый уже существует,
      // приложение под новым именем уже запускалось — перенос затёр бы его данные.
      if old.is_dir() && !new.exists() {
        if let Err(err) = std::fs::rename(&old, &new) {
          eprintln!("[sendoff] не удалось перенести каталог данных {old:?} → {new:?}: {err}");
        }
      }
    }
  }

  #[cfg_attr(not(feature = "mcp-bridge"), allow(unused_mut))]
  let mut builder = tauri::Builder::default()
    // Регистрируется ПЕРВЫМ — требование плагина (плагины стартуют в порядке добавления).
    //
    // Зачем вообще: два инстанса на одной IndexedDB тихо съедают работу друг друга.
    // saveSession не дописывает, а делает clear() + переписывает сторы целиком снапшотом
    // из памяти СВОЕГО инстанса (web/src/lib/db.ts). Поэтому второй инстанс, у которого
    // в памяти состояние на момент его запуска, при первой же записи стирает всё, что
    // первый успел создать после. Хуже того, ему для этого не нужно ничего делать:
    // beforeunload зовёт flushSession(), то есть достаточно ЗАКРЫТЬ лишнее окно.
    //
    // Гард обязан быть нативным: BroadcastChannel и Web Locks не выходят за пределы
    // своего webview-процесса, два инстанса друг друга оттуда не видят.
    //
    // На Linux плагин держит DBus-имя по identifier, а он один и тот же у сборки из
    // исходников и у AppImage — то есть эта пара тоже ловится (случай 2026-08-10).
    .plugin(tauri_plugin_single_instance::init(|app, _argv, _cwd| {
      // Лейбл окна в tauri.conf.json не задан → Tauri даёт дефолтный "main". Фолбэк на
      // любое окно оставлен намеренно: разъехавшийся лейбл иначе дал бы молчаливый no-op,
      // и второй запуск выглядел бы как «приложение не реагирует».
      let window = app
        .get_webview_window("main")
        .or_else(|| app.webview_windows().into_values().next());
      if let Some(window) = window {
        let _ = window.unminimize();
        let _ = window.show();
        let _ = window.set_focus();
      }
    }))
    .plugin(tauri_plugin_dialog::init())
    .plugin(tauri_plugin_fs::init())
    .plugin(tauri_plugin_shell::init());

  #[cfg(feature = "mcp-bridge")]
  {
    // bind loopback only — dev-мост по умолчанию слушает 0.0.0.0, на LAN торчать не должен
    builder = builder.plugin(
      tauri_plugin_mcp_bridge::Builder::new()
        .bind_address("127.0.0.1")
        .build(),
    );
  }

  builder
    .setup(|app| {
      if cfg!(debug_assertions) {
        app.handle().plugin(
          tauri_plugin_log::Builder::default()
            .level(log::LevelFilter::Info)
            .build(),
        )?;
      }
      Ok(())
    })
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
