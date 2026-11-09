/** Writer Linux command guide — single source for shortcuts, overlay, and key handlers. */

export type CommandAction =
  | "commands"
  | "new"
  | "open"
  | "save"
  | "focus"
  | "preview"
  | "night"
  | "typewriter"
  | "library"
  | "style"
  | "stats"
  | "font"
  | "bigger"
  | "smaller";

export type CommandItem = {
  group: string;
  title: string;
  /** Display string, e.g. Ctrl+/ */
  shortcut: string;
  summary: string;
  /** Runnable in-app action; omit for informational editor bindings. */
  action?: CommandAction;
  /** Chord used by the global keydown handler (omitted for CodeMirror-owned keys). */
  chord?: {
    key: string;
    alt?: boolean;
    shift?: boolean;
    /** Extra key aliases (e.g. "+" for "="). */
    keys?: string[];
  };
};

export type CommandRow =
  | { kind: "group"; title: string }
  | { kind: "command"; item: CommandItem };

/**
 * Omarchy / Hyprland use the Super plane for nearly all desktop binds
 * (Super+Space launcher, Super+Ctrl+… panels, etc.). Writer stays on
 * Ctrl / Alt+Ctrl / Shift+Ctrl so it does not steal compositor shortcuts.
 * Near-misses (same letter, different modifier) are intentional and safe:
 * Alt+Ctrl+N (Night) ≠ Super+Ctrl+N (nightlight), etc.
 */
export const COMMANDS: CommandItem[] = [
  {
    group: "Writer",
    title: "Commands…",
    shortcut: "Ctrl+/",
    summary: "Show every command, its shortcut, and what it does. Also Ctrl+?.",
    action: "commands",
    chord: { key: "/", keys: ["?"] },
  },

  {
    group: "File",
    title: "New",
    shortcut: "Ctrl+N",
    summary: "Start a new untitled document.",
    action: "new",
    chord: { key: "n" },
  },
  {
    group: "File",
    title: "Open…",
    shortcut: "Ctrl+O",
    summary: "Open a Markdown or text file.",
    action: "open",
    chord: { key: "o" },
  },
  {
    group: "File",
    title: "Save",
    shortcut: "Ctrl+S",
    summary: "Save the current document (Save As if untitled).",
    action: "save",
    chord: { key: "s" },
  },

  {
    group: "Edit",
    title: "Undo",
    shortcut: "Ctrl+Z",
    summary: "Undo the last edit in the editor.",
  },
  {
    group: "Edit",
    title: "Redo",
    shortcut: "Ctrl+Shift+Z",
    summary: "Redo the last undone edit.",
  },
  {
    group: "Edit",
    title: "Find…",
    shortcut: "Ctrl+F",
    summary: "Search in the current document.",
  },
  {
    group: "Edit",
    title: "Find Next",
    shortcut: "Ctrl+G",
    summary: "Jump to the next match.",
  },
  {
    group: "Edit",
    title: "Find Previous",
    shortcut: "Ctrl+Shift+G",
    summary: "Jump to the previous match.",
  },
  {
    group: "Edit",
    title: "Select All",
    shortcut: "Ctrl+A",
    summary: "Select the whole document.",
  },

  {
    group: "View",
    title: "Focus Mode",
    shortcut: "Ctrl+D",
    summary: "Cycle focus: sentence → paragraph → off. Keeps the caret unit; fades the rest.",
    action: "focus",
    chord: { key: "d" },
  },
  {
    group: "View",
    title: "Preview",
    shortcut: "Ctrl+R",
    summary: "Show rendered HTML beside the editor.",
    action: "preview",
    chord: { key: "r" },
  },
  {
    group: "View",
    title: "Library",
    shortcut: "Alt+Ctrl+L",
    summary: "Toggle the sidebar of Markdown and text files (~/Documents/Writer).",
    action: "library",
    chord: { key: "l", alt: true },
  },
  {
    group: "View",
    title: "Night Mode",
    shortcut: "Alt+Ctrl+N",
    summary: "Cycle appearance: system → dark → light.",
    action: "night",
    chord: { key: "n", alt: true },
  },
  {
    group: "View",
    title: "Typewriter Mode",
    shortcut: "Alt+Ctrl+T",
    summary: "Keep the caret line near the middle of the window.",
    action: "typewriter",
    chord: { key: "t", alt: true },
  },
  {
    group: "View",
    title: "Style Check",
    shortcut: "Alt+Shift+Ctrl+D",
    summary: "Strike fillers, clichés, and redundancies in the editor.",
    action: "style",
    chord: { key: "d", alt: true, shift: true },
  },
  {
    group: "View",
    title: "Word Count",
    shortcut: "Shift+Ctrl+C",
    summary: "Toggle word count and reading time in the status bar.",
    action: "stats",
    chord: { key: "c", shift: true },
  },
  {
    group: "View",
    title: "Cycle Font",
    shortcut: "",
    summary: "Switch between iA Writer Duo, Quattro, and Mono.",
    action: "font",
  },
  {
    group: "View",
    title: "Bigger text",
    shortcut: "Ctrl+=",
    summary: "Increase the editor font size.",
    action: "bigger",
    chord: { key: "=", keys: ["+"] },
  },
  {
    group: "View",
    title: "Smaller text",
    shortcut: "Ctrl+-",
    summary: "Decrease the editor font size.",
    action: "smaller",
    chord: { key: "-" },
  },
];

export function matchingCommands(query: string): CommandItem[] {
  const needle = query.trim().toLowerCase();
  if (!needle) return COMMANDS;
  return COMMANDS.filter((item) =>
    [item.group, item.title, item.shortcut, item.summary].some((field) =>
      field.toLowerCase().includes(needle),
    ),
  );
}

export function commandRows(query: string): CommandRow[] {
  const rows: CommandRow[] = [];
  let current: string | undefined;
  for (const item of matchingCommands(query)) {
    if (item.group !== current) {
      rows.push({ kind: "group", title: item.group });
      current = item.group;
    }
    rows.push({ kind: "command", item });
  }
  return rows;
}

export function matchChord(
  event: Pick<KeyboardEvent, "key" | "altKey" | "shiftKey">,
  chord: NonNullable<CommandItem["chord"]>,
): boolean {
  const key = event.key.toLowerCase();
  const wanted = [chord.key, ...(chord.keys ?? [])].map((k) => k.toLowerCase());
  if (!wanted.includes(key)) return false;
  if (!!chord.alt !== event.altKey) return false;
  // Commands: Ctrl+/ and Ctrl+? (Shift+/) both open the guide — ignore Shift.
  if (chord.key === "/") return true;
  // Bigger text: Ctrl+= and Ctrl++ (Shift+=) — ignore Shift when key is "+".
  if (key === "+" && (chord.keys ?? []).includes("+")) return true;
  if (!!chord.shift !== event.shiftKey) return false;
  return true;
}

export function findActionForEvent(
  event: Pick<KeyboardEvent, "key" | "altKey" | "shiftKey" | "ctrlKey" | "metaKey">,
): CommandAction | null {
  if (!(event.ctrlKey || event.metaKey)) return null;
  for (const item of COMMANDS) {
    if (!item.action || !item.chord) continue;
    if (matchChord(event, item.chord)) return item.action;
  }
  return null;
}
