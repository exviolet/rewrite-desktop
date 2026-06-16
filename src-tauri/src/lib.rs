#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
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
