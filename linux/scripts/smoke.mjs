import { computeStats, statsSummary, readingMinutes } from "../src/lib/stats.ts";
import { focusRange } from "../src/lib/focus.ts";
import { styleSpans } from "../src/lib/style-check.ts";
import {
  COMMANDS,
  commandRows,
  findActionForEvent,
  matchingCommands,
} from "../src/lib/commands.ts";

function assert(cond, msg) {
  if (!cond) throw new Error(msg);
}

const stats = computeStats("One two three. Four five.");
assert(stats.words === 5, `expected 5 words, got ${stats.words}`);
assert(readingMinutes(275) === 1, "275 words => 1 min");
assert(statsSummary(stats).includes("5 words"), "summary includes word count");

const text = "Hello world. Second sentence here.";
const sentence = focusRange("sentence", 2, text);
assert(sentence && sentence.from === 0, "sentence focus starts at 0");
const paragraph = focusRange("paragraph", 20, text);
assert(paragraph && paragraph.from === 0, "single paragraph from 0");
assert(focusRange("off", 0, text) === null, "off => null");

const sample = "Actually, the end result was to think outside the box.";
const spans = styleSpans(sample, new Set(["filler", "redundancy", "cliche"]));
assert(spans.some((s) => s.kind === "filler"), "detects filler");
assert(spans.some((s) => s.kind === "redundancy"), "detects redundancy");
assert(spans.some((s) => s.kind === "cliche"), "detects cliche");

assert(COMMANDS.some((c) => c.action === "commands"), "commands action listed");
assert(matchingCommands("focus").some((c) => c.title === "Focus Mode"), "filter finds Focus");
assert(commandRows("").filter((r) => r.kind === "group").length >= 3, "grouped rows");
assert(
  findActionForEvent({ key: "/", altKey: false, shiftKey: false, ctrlKey: true, metaKey: false }) ===
    "commands",
  "Ctrl+/ opens commands",
);
assert(
  findActionForEvent({ key: "?", altKey: false, shiftKey: true, ctrlKey: true, metaKey: false }) ===
    "commands",
  "Ctrl+? opens commands",
);
assert(
  findActionForEvent({ key: "d", altKey: false, shiftKey: false, ctrlKey: true, metaKey: false }) ===
    "focus",
  "Ctrl+D focus",
);
assert(
  findActionForEvent({ key: "n", altKey: true, shiftKey: false, ctrlKey: true, metaKey: false }) ===
    "night",
  "Alt+Ctrl+N night",
);
assert(
  findActionForEvent({ key: "d", altKey: true, shiftKey: true, ctrlKey: true, metaKey: false }) ===
    "style",
  "Alt+Shift+Ctrl+D style",
);

console.log("linux smoke ok");
