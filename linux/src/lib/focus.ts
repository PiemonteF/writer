/** Port of Sources/Writer/Text/FocusRange.swift */
export type FocusMode = "off" | "sentence" | "paragraph";

export type CharRange = { from: number; to: number };

function paragraphRange(text: string, caret: number): CharRange {
  const len = text.length;
  let from = caret;
  while (from > 0 && text[from - 1] !== "\n") from -= 1;
  let to = caret;
  while (to < len && text[to] !== "\n") to += 1;
  // include trailing newline like NSString.paragraphRange
  if (to < len && text[to] === "\n") to += 1;
  return { from, to };
}

function sentenceRangesInParagraph(text: string, paragraph: CharRange): CharRange[] {
  const slice = text.slice(paragraph.from, paragraph.to);
  const ranges: CharRange[] = [];
  const re = /[^.!?…\n]+(?:[.!?…]+|\n|$)/gu;
  let match: RegExpExecArray | null;
  while ((match = re.exec(slice)) !== null) {
    const from = paragraph.from + match.index;
    const to = from + match[0].length;
    if (match[0].trim().length > 0) ranges.push({ from, to });
  }
  return ranges.length ? ranges : [paragraph];
}

export function focusRange(
  mode: FocusMode,
  caret: number,
  text: string,
): CharRange | null {
  if (mode === "off") return null;
  if (caret < 0 || caret > text.length) return null;
  const paragraph = paragraphRange(text, Math.min(caret, Math.max(0, text.length)));
  if (mode === "paragraph") return paragraph;

  const sentences = sentenceRangesInParagraph(text, paragraph);
  let containing: CharRange | null = null;
  let preceding: CharRange | null = null;
  for (const sentence of sentences) {
    if (caret >= sentence.from && caret < sentence.to) {
      containing = sentence;
      break;
    }
    if (sentence.to === caret) preceding = sentence;
  }
  return containing ?? preceding ?? paragraph;
}
