import {
  EditorView,
  keymap,
  drawSelection,
  Decoration,
  ViewPlugin,
  type DecorationSet,
  type ViewUpdate,
} from "@codemirror/view";
import { EditorState, Compartment, type Extension } from "@codemirror/state";
import { markdown } from "@codemirror/lang-markdown";
import { defaultKeymap, history, historyKeymap, indentWithTab } from "@codemirror/commands";
import { searchKeymap, highlightSelectionMatches } from "@codemirror/search";
import { syntaxHighlighting, HighlightStyle } from "@codemirror/language";
import { tags } from "@lezer/highlight";
import { focusRange, type FocusMode } from "./focus";
import { styleSpans, type StyleIssue } from "./style-check";
import { FONT_FAMILIES, THEME, type EditorFont } from "./preferences";

export type EditorCallbacks = {
  onChange: (text: string) => void;
  onCursor: (pos: number) => void;
};

export type EditorChrome = {
  font: EditorFont;
  fontSize: number;
  dark: boolean;
  lineLength: number;
  focusMode: FocusMode;
  typewriter: boolean;
  styleChecks: Set<StyleIssue>;
};

const overlayCompartment = new Compartment();
const themeCompartment = new Compartment();

function writerHighlight(dark: boolean) {
  const colors = dark ? THEME.dark : THEME.light;
  return syntaxHighlighting(
    HighlightStyle.define([
      { tag: tags.heading, fontWeight: "700", color: colors.text },
      { tag: tags.strong, fontWeight: "700" },
      { tag: tags.emphasis, fontStyle: "italic" },
      { tag: tags.monospace, fontFamily: FONT_FAMILIES.mono, color: colors.text },
      { tag: tags.processingInstruction, color: colors.markup },
      { tag: tags.meta, color: colors.markup },
      { tag: tags.link, color: colors.accent },
      { tag: tags.url, color: colors.accent },
      { tag: tags.quote, color: colors.markup, fontStyle: "italic" },
      { tag: tags.list, color: colors.markup },
      { tag: tags.contentSeparator, color: colors.markup },
    ]),
  );
}

function baseTheme(chrome: EditorChrome) {
  const colors = chrome.dark ? THEME.dark : THEME.light;
  const maxCh = chrome.lineLength;
  return EditorView.theme(
    {
      "&": {
        height: "100%",
        backgroundColor: colors.background,
        color: colors.text,
        fontFamily: FONT_FAMILIES[chrome.font],
        fontSize: `${chrome.fontSize}px`,
      },
      ".cm-scroller": {
        fontFamily: FONT_FAMILIES[chrome.font],
        lineHeight: "1.5",
        overflow: "auto",
      },
      ".cm-content": {
        maxWidth: `${maxCh}ch`,
        margin: "0 auto",
        padding: chrome.typewriter ? "40vh 24px" : "40px 24px 96px",
        caretColor: colors.accent,
      },
      ".cm-cursor, .cm-dropCursor": {
        borderLeftColor: colors.accent,
      },
      "&.cm-focused .cm-selectionBackground, .cm-selectionBackground, .cm-content ::selection": {
        backgroundColor: chrome.dark ? "#2F4A6A88" : "#2F7CF633",
      },
      ".cm-gutters": {
        display: "none",
      },
      ".cm-activeLine": {
        backgroundColor: "transparent",
      },
      ".cm-focus-dim": {
        color: `${colors.dimmed} !important`,
      },
      ".cm-style-strike": {
        textDecoration: `line-through ${colors.dimmed}`,
        color: colors.dimmed,
      },
    },
    { dark: chrome.dark },
  );
}

function overlayPlugin(chrome: () => EditorChrome) {
  return ViewPlugin.fromClass(
    class {
      decorations: DecorationSet;

      constructor(view: EditorView) {
        this.decorations = this.build(view);
      }

      update(update: ViewUpdate) {
        if (
          update.docChanged ||
          update.selectionSet ||
          update.viewportChanged
        ) {
          this.decorations = this.build(update.view);
        }
      }

      build(view: EditorView): DecorationSet {
        const prefs = chrome();
        const text = view.state.doc.toString();
        const caret = view.state.selection.main.head;
        const builder: { from: number; to: number; value: ReturnType<typeof Decoration.mark> }[] = [];

        const focus = focusRange(prefs.focusMode, caret, text);
        if (focus) {
          if (focus.from > 0) {
            builder.push({
              from: 0,
              to: focus.from,
              value: Decoration.mark({ class: "cm-focus-dim" }),
            });
          }
          if (focus.to < text.length) {
            builder.push({
              from: focus.to,
              to: text.length,
              value: Decoration.mark({ class: "cm-focus-dim" }),
            });
          }
        }

        for (const span of styleSpans(text, prefs.styleChecks)) {
          builder.push({
            from: span.from,
            to: span.to,
            value: Decoration.mark({ class: "cm-style-strike" }),
          });
        }

        builder.sort((a, b) => a.from - b.from || a.to - b.to);
        return Decoration.set(builder);
      }
    },
    { decorations: (v) => v.decorations },
  );
}

export function createEditor(
  parent: HTMLElement,
  initial: string,
  chrome: EditorChrome,
  callbacks: EditorCallbacks,
): {
  view: EditorView;
  setText: (text: string) => void;
  getText: () => string;
  reconfigure: (next: EditorChrome) => void;
  focus: () => void;
} {
  let current = chrome;

  const extensions: Extension[] = [
    history(),
    drawSelection(),
    markdown(),
    highlightSelectionMatches(),
    keymap.of([...defaultKeymap, ...historyKeymap, ...searchKeymap, indentWithTab]),
    EditorView.lineWrapping,
    EditorView.updateListener.of((update) => {
      if (update.docChanged) callbacks.onChange(update.state.doc.toString());
      if (update.selectionSet || update.docChanged) {
        callbacks.onCursor(update.state.selection.main.head);
        if (current.typewriter) {
          const coords = update.view.coordsAtPos(update.state.selection.main.head);
          if (coords) {
            const scroller = update.view.scrollDOM;
            const mid = scroller.clientHeight / 2;
            const target = scroller.scrollTop + (coords.top - scroller.getBoundingClientRect().top) - mid;
            scroller.scrollTop = target;
          }
        }
      }
    }),
    themeCompartment.of([baseTheme(current), writerHighlight(current.dark)]),
    overlayCompartment.of(overlayPlugin(() => current)),
  ];

  const state = EditorState.create({
    doc: initial,
    extensions,
  });

  const view = new EditorView({ state, parent });

  return {
    view,
    setText(text: string) {
      view.dispatch({
        changes: { from: 0, to: view.state.doc.length, insert: text },
      });
    },
    getText() {
      return view.state.doc.toString();
    },
    reconfigure(next: EditorChrome) {
      current = next;
      view.dispatch({
        effects: [
          themeCompartment.reconfigure([baseTheme(next), writerHighlight(next.dark)]),
          overlayCompartment.reconfigure(overlayPlugin(() => current)),
        ],
      });
    },
    focus() {
      view.focus();
    },
  };
}
