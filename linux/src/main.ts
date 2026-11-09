import { invoke } from "@tauri-apps/api/core";
import { open, save } from "@tauri-apps/plugin-dialog";
import { marked } from "marked";
import { mountCommandGuide } from "./lib/command-guide";
import { findActionForEvent, type CommandAction } from "./lib/commands";
import { createEditor } from "./lib/editor";
import {
  FONT_CYCLE,
  loadPreferences,
  savePreferences,
  resolveDark,
  type Preferences,
} from "./lib/preferences";
import { computeStats, statsSummary } from "./lib/stats";
import type { StyleIssue } from "./lib/style-check";

type LibraryEntry = {
  name: string;
  path: string;
  relative: string;
  isDir: boolean;
};

const UNTITLED = "# Untitled\n\n";

const DEMO = `# The quiet page

A simple place with no AI. If there is any, you know.

Authentic thoughts. *Yours.*

> Write until the room goes still.

- Keep the chrome quiet
- Let the page stay white
- Trust the keys
`;

let prefs: Preferences;
let currentPath: string | null = null;
let dirty = false;
let statsTimer: number | undefined;

const workspace = document.querySelector<HTMLElement>("#workspace")!;
const libraryEl = document.querySelector<HTMLElement>("#library")!;
const libraryList = document.querySelector<HTMLUListElement>("#library-list")!;
const librarySearch = document.querySelector<HTMLInputElement>("#library-search")!;
const statsEl = document.querySelector<HTMLElement>("#stats")!;
const docTitle = document.querySelector<HTMLElement>("#doc-title")!;
const commandsDialog = document.querySelector<HTMLDialogElement>("#commands")!;
const previewFrame = document.querySelector<HTMLIFrameElement>("#preview")!;

function chromeFromPrefs() {
  return {
    font: prefs.font,
    fontSize: prefs.fontSize,
    dark: resolveDark(prefs.appearance),
    lineLength: prefs.lineLength,
    focusMode: prefs.focusMode,
    typewriter: prefs.typewriter,
    styleChecks: new Set<StyleIssue>(prefs.styleChecks),
  };
}

function applyShellTheme() {
  const dark = resolveDark(prefs.appearance);
  document.documentElement.dataset.theme = dark ? "dark" : "light";
  workspace.classList.toggle("library-open", prefs.showLibrary);
  workspace.classList.toggle("preview-on", prefs.showPreview);
  libraryEl.classList.toggle("hidden", !prefs.showLibrary);
  statsEl.classList.toggle("hidden", !prefs.showStats);
}

function setTitle() {
  const base = currentPath ? currentPath.split(/[\\/]/).pop()! : "Untitled";
  docTitle.textContent = dirty ? `${base} ·` : base;
  document.title = dirty ? `${base} — Writer` : `${base} · Writer`;
}

function persist() {
  savePreferences(prefs);
  applyShellTheme();
  editor.reconfigure(chromeFromPrefs());
  updatePreview(editor.getText());
}

function scheduleStats(text: string) {
  window.clearTimeout(statsTimer);
  statsTimer = window.setTimeout(() => {
    statsEl.textContent = statsSummary(computeStats(text));
  }, 200);
}

function updatePreview(text: string) {
  if (!prefs.showPreview) return;
  const dark = resolveDark(prefs.appearance);
  const body = marked.parse(text, { async: false }) as string;
  const html = `<!doctype html>
<html data-theme="${dark ? "dark" : "light"}">
<head>
<meta charset="utf-8"/>
<link rel="stylesheet" href="/preview.css"/>
<style>
  :root { color-scheme: ${dark ? "dark" : "light"}; }
  ${
    dark
      ? `:root { --bg:#1E1E1E; --text:#E6E6E6; --muted:#9A9A9A; --rule:#333; --code-bg:#2A2A2A; --accent:#4A90FF; }`
      : ""
  }
  body { font-family: "iA Writer Quattro S", "iA Writer Duo S", ui-sans-serif, system-ui, sans-serif; }
</style>
</head>
<body><article>${body}</article></body>
</html>`;
  previewFrame.srcdoc = html;
}

async function refreshLibrary(query = "") {
  try {
    await invoke("ensure_library", { path: prefs.libraryPath });
    const entries = await invoke<LibraryEntry[]>("list_library", {
      path: prefs.libraryPath,
      query: query || null,
    });
    libraryList.innerHTML = "";
    let lastDir = "";
    for (const entry of entries) {
      if (entry.isDir) continue;
      const dir = entry.relative.includes("/")
        ? entry.relative.slice(0, entry.relative.lastIndexOf("/"))
        : "";
      if (dir !== lastDir) {
        lastDir = dir;
        const label = document.createElement("li");
        label.className = "dir";
        label.textContent = dir || "Library";
        libraryList.append(label);
      }
      const li = document.createElement("li");
      const btn = document.createElement("button");
      btn.type = "button";
      btn.textContent = entry.name;
      btn.classList.toggle("active", entry.path === currentPath);
      btn.addEventListener("click", () => void openPath(entry.path));
      li.append(btn);
      libraryList.append(li);
    }
  } catch (err) {
    console.error(err);
  }
}

async function openPath(path: string) {
  if (dirty && !window.confirm("Discard unsaved changes?")) return;
  const text = await invoke<string>("read_text_file", { path });
  currentPath = path;
  dirty = false;
  editor.setText(text);
  setTitle();
  scheduleStats(text);
  updatePreview(text);
  await refreshLibrary(librarySearch.value);
  editor.focus();
}

function newDocument() {
  if (dirty && !window.confirm("Discard unsaved changes?")) return;
  currentPath = null;
  dirty = false;
  editor.setText(UNTITLED);
  setTitle();
  scheduleStats(UNTITLED);
  updatePreview(UNTITLED);
  editor.focus();
}

async function openDialog() {
  const selected = await open({
    multiple: false,
    filters: [{ name: "Markdown", extensions: ["md", "markdown", "txt"] }],
  });
  if (typeof selected === "string") await openPath(selected);
}

async function saveDocument() {
  let path = currentPath;
  if (!path) {
    const picked = await save({
      defaultPath: `${prefs.libraryPath}/Untitled.md`,
      filters: [{ name: "Markdown", extensions: ["md"] }],
    });
    if (!picked) return;
    path = picked;
  }
  await invoke("write_text_file", { path, contents: editor.getText() });
  currentPath = path;
  dirty = false;
  setTitle();
  await refreshLibrary(librarySearch.value);
}

function toggleFocus() {
  prefs.focusMode = prefs.focusMode === "off" ? "sentence" : prefs.focusMode === "sentence" ? "paragraph" : "off";
  persist();
}

function toggleStyle() {
  prefs.styleChecks =
    prefs.styleChecks.length === 0 ? (["filler", "redundancy", "cliche"] as StyleIssue[]) : [];
  persist();
}

function cycleNight() {
  prefs.appearance =
    prefs.appearance === "system" ? "dark" : prefs.appearance === "dark" ? "light" : "system";
  persist();
}

function runCommand(action: CommandAction) {
  switch (action) {
    case "commands":
      guide.toggle();
      break;
    case "new":
      newDocument();
      break;
    case "open":
      void openDialog();
      break;
    case "save":
      void saveDocument();
      break;
    case "focus":
      toggleFocus();
      break;
    case "preview":
      prefs.showPreview = !prefs.showPreview;
      persist();
      break;
    case "night":
      cycleNight();
      break;
    case "typewriter":
      prefs.typewriter = !prefs.typewriter;
      persist();
      break;
    case "library":
      prefs.showLibrary = !prefs.showLibrary;
      persist();
      break;
    case "style":
      toggleStyle();
      break;
    case "stats":
      prefs.showStats = !prefs.showStats;
      persist();
      break;
    case "font": {
      const i = FONT_CYCLE.indexOf(prefs.font);
      prefs.font = FONT_CYCLE[(i + 1) % FONT_CYCLE.length]!;
      persist();
      break;
    }
    case "bigger":
      prefs.fontSize = Math.min(40, prefs.fontSize + 1);
      persist();
      break;
    case "smaller":
      prefs.fontSize = Math.max(12, prefs.fontSize - 1);
      persist();
      break;
  }
}

const guide = mountCommandGuide(commandsDialog, { run: runCommand });

const editor = createEditor(
  document.querySelector("#editor")!,
  UNTITLED,
  {
    font: "duo",
    fontSize: 17,
    dark: false,
    lineLength: 66,
    focusMode: "off",
    typewriter: false,
    styleChecks: new Set(),
  },
  {
    onChange(text) {
      dirty = true;
      setTitle();
      scheduleStats(text);
      updatePreview(text);
    },
    onCursor() {
      /* overlays refresh via CodeMirror selection updates */
    },
  },
);

async function bootstrap() {
  let libraryPath = "";
  try {
    libraryPath = await invoke<string>("default_library_path");
  } catch {
    libraryPath = "";
  }
  prefs = loadPreferences(libraryPath);
  if (!prefs.libraryPath) prefs.libraryPath = libraryPath;
  applyShellTheme();
  editor.reconfigure(chromeFromPrefs());
  if (new URLSearchParams(location.search).has("demo")) {
    editor.setText(DEMO);
    dirty = false;
  }
  scheduleStats(editor.getText());
  await refreshLibrary();
  setTitle();
  editor.focus();
}

document.querySelector(".sr-toolbar")!.addEventListener("click", (event) => {
  const target = (event.target as HTMLElement).closest<HTMLButtonElement>("button[data-action]");
  if (!target?.dataset.action) return;
  runCommand(target.dataset.action as CommandAction);
});

librarySearch.addEventListener("input", () => {
  void refreshLibrary(librarySearch.value);
});

window.addEventListener("keydown", (event) => {
  if (!(event.ctrlKey || event.metaKey)) return;
  // Let the guide handle its own arrows / Enter / Esc while open,
  // except Ctrl+/ which toggles it closed.
  const action = findActionForEvent(event);
  if (!action) return;
  if (guide.isOpen() && action !== "commands") return;
  event.preventDefault();
  runCommand(action);
});

window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
  if (prefs.appearance === "system") persist();
});

void bootstrap();
