fn main() {
  // Команды приложения по умолчанию разрешены всем окнам и в ACL не попадают —
  // то есть запись файлов была бы не видна в capabilities/default.json, а именно
  // там у проекта описана граница. Перечисление здесь заводит команду в ACL:
  // её приходится выдать в манифесте явно, как плагинную.
  tauri_build::try_build(
    tauri_build::Attributes::new()
      .app_manifest(tauri_build::AppManifest::new().commands(&["save_clipboard_image"])),
  )
  .expect("failed to run tauri-build")
}
