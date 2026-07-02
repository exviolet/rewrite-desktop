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

  #[cfg_attr(not(feature = "mcp-bridge"), allow(unused_mut))]
  let mut builder = tauri::Builder::default()
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
