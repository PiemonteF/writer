import type { FocusMode } from "./focus";
import type { StyleIssue } from "./style-check";

export type EditorFont = "duo" | "quattro" | "mono";
export type Appearance = "system" | "light" | "dark";

export type Preferences = {
  font: EditorFont;
  fontSize: number;
  appearance: Appearance;
  focusMode: FocusMode;
  typewriter: boolean;
  showStats: boolean;
  lineLength: number;
  showLibrary: boolean;
  showPreview: boolean;
  libraryPath: string;
  styleChecks: StyleIssue[];
};

const KEY = "writer.preferences.v2";

export const FONT_FAMILIES: Record<EditorFont, string> = {
  duo: '"iA Writer Duo S", "iA Duo", ui-sans-serif, system-ui, sans-serif',
  quattro: '"iA Writer Quattro S", "iA Quattro", ui-sans-serif, system-ui, sans-serif',
  mono: '"iA Writer Mono S", "iA Mono", ui-monospace, monospace',
};

export const FONT_CYCLE: EditorFont[] = ["duo", "quattro", "mono"];

export const THEME = {
  light: {
    background: "#FCFCFC",
    text: "#1A1A1A",
    dimmed: "#BFBFBF",
    markup: "#8E9AA8",
    accent: "#2F7CF6",
    panel: "#FCFCFC",
    border: "#ECECEC",
    codeBg: "#F2F2F2",
  },
  dark: {
    background: "#1E1E1E",
    text: "#E6E6E6",
    dimmed: "#575757",
    markup: "#6C7885",
    accent: "#4A90FF",
    panel: "#1E1E1E",
    border: "#2A2A2A",
    codeBg: "#2A2A2A",
  },
} as const;

export function defaultPreferences(libraryPath = ""): Preferences {
  return {
    font: "duo",
    fontSize: 17,
    appearance: "light",
    focusMode: "off",
    typewriter: false,
    showStats: true,
    lineLength: 66,
    showLibrary: false,
    showPreview: false,
    libraryPath,
    styleChecks: [],
  };
}

export function loadPreferences(libraryPath = ""): Preferences {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return defaultPreferences(libraryPath);
    const parsed = JSON.parse(raw) as Partial<Preferences>;
    return { ...defaultPreferences(libraryPath), ...parsed };
  } catch {
    return defaultPreferences(libraryPath);
  }
}

export function savePreferences(prefs: Preferences): void {
  localStorage.setItem(KEY, JSON.stringify(prefs));
}

export function resolveDark(appearance: Appearance): boolean {
  if (appearance === "dark") return true;
  if (appearance === "light") return false;
  return window.matchMedia("(prefers-color-scheme: dark)").matches;
}
