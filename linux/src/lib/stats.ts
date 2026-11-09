/** Port of Sources/Writer/Text/TextStatistics.swift */
export type TextStatistics = {
  words: number;
  characters: number;
  sentences: number;
  paragraphs: number;
};

export const WORDS_PER_MINUTE = 275;

export function readingMinutes(words: number): number {
  return words === 0 ? 0 : Math.max(1, Math.ceil(words / WORDS_PER_MINUTE));
}

export function computeStats(text: string): TextStatistics {
  const trimmed = text.replace(/\s+$/u, "");
  const words = trimmed.trim() === "" ? 0 : (trimmed.trim().match(/\S+/gu) ?? []).length;
  const characters = [...text].length;
  const sentences =
    trimmed.trim() === ""
      ? 0
      : (trimmed.match(/[^.!?…]+[.!?…]+|[^.!?…]+$/gu) ?? []).filter((s) => s.trim().length > 0)
          .length;
  const paragraphs =
    trimmed.trim() === ""
      ? 0
      : trimmed.split(/\n{2,}/u).filter((p) => p.trim().length > 0).length ||
        (trimmed.trim() ? 1 : 0);
  return { words, characters, sentences, paragraphs };
}

export function statsSummary(stats: TextStatistics): string {
  const label = stats.words === 1 ? "word" : "words";
  const formatted = stats.words.toLocaleString();
  return `${formatted} ${label} · ${readingMinutes(stats.words)} min`;
}
