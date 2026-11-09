use serde::Serialize;
use std::fs;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct LibraryEntry {
    name: String,
    path: String,
    relative: String,
    is_dir: bool,
}

fn is_text_doc(path: &Path) -> bool {
    matches!(
        path.extension().and_then(|e| e.to_str()).map(|e| e.to_ascii_lowercase()),
        Some(ref e) if e == "md" || e == "markdown" || e == "txt"
    )
}

#[tauri::command]
fn default_library_path() -> Result<String, String> {
    let home = dirs_home().ok_or_else(|| "home directory not found".to_string())?;
    Ok(home.join("Documents").join("Writer").to_string_lossy().into_owned())
}

fn dirs_home() -> Option<PathBuf> {
    std::env::var_os("HOME").map(PathBuf::from)
}

#[tauri::command]
fn ensure_library(path: String) -> Result<(), String> {
    let dir = PathBuf::from(&path);
    fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    let welcome = dir.join("Welcome.md");
    if !welcome.exists() {
        fs::write(
            &welcome,
            "# Welcome to Writer\n\nA simple place with no AI. If there is any, you know.\n\nAuthentic thoughts. Yours.\n\nStart typing, or open a file from the library.\n",
        )
        .map_err(|e| e.to_string())?;
    }
    Ok(())
}

#[tauri::command]
fn list_library(path: String, query: Option<String>) -> Result<Vec<LibraryEntry>, String> {
    let root = PathBuf::from(&path);
    if !root.exists() {
        return Ok(vec![]);
    }
    let q = query.unwrap_or_default().trim().to_ascii_lowercase();
    let mut entries = Vec::new();
    for entry in WalkDir::new(&root)
        .follow_links(false)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        let p = entry.path();
        if p == root {
            continue;
        }
        let is_dir = entry.file_type().is_dir();
        if !is_dir && !is_text_doc(p) {
            continue;
        }
        let name = entry
            .file_name()
            .to_string_lossy()
            .into_owned();
        if !q.is_empty() {
            let hay = format!(
                "{} {}",
                name.to_ascii_lowercase(),
                p.strip_prefix(&root)
                    .unwrap_or(p)
                    .to_string_lossy()
                    .to_ascii_lowercase()
            );
            if !hay.contains(&q) {
                continue;
            }
            // when searching, skip empty dirs
            if is_dir {
                continue;
            }
        }
        let relative = p
            .strip_prefix(&root)
            .unwrap_or(p)
            .to_string_lossy()
            .into_owned();
        entries.push(LibraryEntry {
            name,
            path: p.to_string_lossy().into_owned(),
            relative,
            is_dir,
        });
    }
    entries.sort_by(|a, b| match (a.is_dir, b.is_dir) {
        (true, false) => std::cmp::Ordering::Less,
        (false, true) => std::cmp::Ordering::Greater,
        _ => a.relative.to_ascii_lowercase().cmp(&b.relative.to_ascii_lowercase()),
    });
    Ok(entries)
}

#[tauri::command]
fn read_text_file(path: String) -> Result<String, String> {
    fs::read_to_string(&path).map_err(|e| e.to_string())
}

#[tauri::command]
fn write_text_file(path: String, contents: String) -> Result<(), String> {
    if let Some(parent) = Path::new(&path).parent() {
        fs::create_dir_all(parent).map_err(|e| e.to_string())?;
    }
    fs::write(&path, contents).map_err(|e| e.to_string())
}

#[tauri::command]
fn file_basename(path: String) -> String {
    Path::new(&path)
        .file_name()
        .map(|s| s.to_string_lossy().into_owned())
        .unwrap_or_else(|| path)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .invoke_handler(tauri::generate_handler![
            default_library_path,
            ensure_library,
            list_library,
            read_text_file,
            write_text_file,
            file_basename,
        ])
        .run(tauri::generate_context!())
        .expect("error while running Writer");
}
