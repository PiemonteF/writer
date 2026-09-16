#!/usr/bin/env python3
"""Render README screenshots of Writer with the bundled iA fonts and theme colors."""

from __future__ import annotations

import http.server
import os
import shutil
import subprocess
import threading
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "screenshots"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

LIGHT = {
    "bg": "#FCFCFC",
    "text": "#1A1A1A",
    "dim": "#BFBFBF",
    "markup": "#8E9AA8",
    "accent": "#2F7CF6",
    "stage": "#E4E2DC",
    "noun": "#C44C4C",
    "verb": "#2F7CF6",
    "adjective": "#B8860B",
    "adverb": "#C45A9A",
    "conjunction": "#3F9F57",
    "sidebar": "#F3F3F3",
    "rule": "#E4E4E4",
    "title": "rgba(26,26,26,0.55)",
    "search": "#E8E8E8",
    "selected": "#E3EEFC",
    "muted": "#6E6E6E",
}
DARK = {
    "bg": "#1E1E1E",
    "text": "#E6E6E6",
    "dim": "#575757",
    "markup": "#6C7885",
    "accent": "#4A90FF",
    "stage": "#0C0C0C",
    "noun": "#FF6B66",
    "verb": "#5B9BFF",
    "adjective": "#D8A62B",
    "adverb": "#E090B0",
    "conjunction": "#5FC27A",
    "sidebar": "#252525",
    "rule": "#333333",
    "title": "rgba(230,230,230,0.5)",
    "search": "#2C2C2C",
    "selected": "#2A3A52",
    "muted": "#9A9A9A",
}

MK = "<span class='mk'>{0}</span>"


def prose() -> str:
    return f"""
<p>Write like nobody is watching. The page is a room with the door closed, and the only sound is the sentence you are still deciding.</p>
<p>A good sentence {MK.format('*')}<em>earns</em>{MK.format('*')} its keep. A {MK.format('**')}<strong>great</strong>{MK.format('**')} one makes the next one inevitable.</p>
<p class="quote">{MK.format('> ')}Clarity is the courtesy you owe the reader.</p>
<p>The rest is craft:</p>
<p class="li">{MK.format('- ')}Cut the word you only wrote to sound clever</p>
<p class="li">{MK.format('- ')}Keep the one that still surprises you</p>
<p class="li last">{MK.format('- ')}Stop when the thought is finished, not when the paragraph looks full</p>
<p>That is enough. Close the file before you start explaining it.</p>
"""


def heading() -> str:
    return f"<p class='h'>{MK.format('# ')}The quiet page</p>"


def syntax_prose() -> str:
    def w(kind: str, word: str) -> str:
        return f"<span class='{kind}'>{word}</span>"

    return f"""
<p>{w('verb','Write')} like {w('noun','nobody')} {w('verb','is')} {w('verb','watching')}. {w('noun','The')} {w('noun','page')} {w('verb','is')} a {w('noun','room')} with the {w('noun','door')} {w('verb','closed')}, {w('conjunction','and')} the {w('adjective','only')} {w('noun','sound')} {w('verb','is')} the {w('noun','sentence')} you {w('verb','are')} {w('adverb','still')} {w('verb','deciding')}.</p>
<p>A {w('adjective','good')} {w('noun','sentence')} {MK.format('*')}<em class="verb">earns</em>{MK.format('*')} its {w('verb','keep')}. A {MK.format('**')}<strong class="adjective">great</strong>{MK.format('**')} one {w('verb','makes')} the {w('adjective','next')} one {w('adjective','inevitable')}.</p>
<p class="quote">{MK.format('> ')}{w('noun','Clarity')} {w('verb','is')} the {w('noun','courtesy')} you {w('verb','owe')} the {w('noun','reader')}.</p>
<p>{w('noun','The')} {w('noun','rest')} {w('verb','is')} {w('noun','craft')}:</p>
<p class="li">{MK.format('- ')}{w('noun','Cut')} the {w('noun','word')} you {w('adverb','only')} {w('verb','wrote')} to {w('verb','sound')} {w('adjective','clever')}</p>
<p class="li">{MK.format('- ')}{w('verb','Keep')} the one that {w('adverb','still')} {w('verb','surprises')} you</p>
<p class="li last">{MK.format('- ')}{w('noun','Stop')} when the {w('noun','thought')} {w('verb','is')} {w('verb','finished')}, {w('adverb','not')} when the {w('noun','paragraph')} {w('verb','looks')} {w('adjective','full')}</p>
<p>That {w('verb','is')} {w('adverb','enough')}. {w('adverb','Close')} the {w('noun','file')} before you {w('verb','start')} {w('verb','explaining')} it.</p>
"""


def focus_prose() -> str:
    return f"""
<p><span class="hot">Write like nobody is watching.<span class="caret"></span></span> The page is a room with the door closed, and the only sound is the sentence you are still deciding.</p>
<p>A good sentence {MK.format('*')}<em>earns</em>{MK.format('*')} its keep. A {MK.format('**')}<strong>great</strong>{MK.format('**')} one makes the next one inevitable.</p>
<p class="quote">{MK.format('> ')}Clarity is the courtesy you owe the reader.</p>
<p>The rest is craft:</p>
<p class="li">{MK.format('- ')}Cut the word you only wrote to sound clever</p>
<p class="li">{MK.format('- ')}Keep the one that still surprises you</p>
<p class="li last">{MK.format('- ')}Stop when the thought is finished, not when the paragraph looks full</p>
<p>That is enough. Close the file before you start explaining it.</p>
"""


AI_PALETTE = ["#C46A38", "#6B5CA8", "#C45A7A", "#2E8F78", "#B8860B", "#3A6FA0"]


def color_ai(text: str) -> str:
    parts = []
    for i, word in enumerate(text.split(" ")):
        parts.append(f"<span style='color:{AI_PALETTE[i % len(AI_PALETTE)]}'>{word}</span>")
    return " ".join(parts)


def authorship() -> str:
    pasted = color_ai(
        "In today's rapidly evolving landscape, leveraging authentic storytelling is absolutely essential for any writer who wants to think outside the box."
    )
    return f"""
<p class="h">{MK.format('# ')}The quiet page</p>
<p>Write like nobody is watching. The page is a room with the door closed, and the only sound is the sentence you are still deciding.</p>
<p>{pasted}</p>
<p>That is enough. Close the file before you start explaining it.</p>
"""


def workshop() -> str:
    strike = lambda s: f"<span class='strike'>{s}</span>"
    return f"""
<p class="h">{MK.format('# ')}Workshop</p>
<p>{strike('In order to')} {strike('actually')} write something {strike('pretty much')} worth reading, people {strike('think outside the box')}. The {strike('end result')} is often an {strike('unexpected surprise')}.</p>
<p>The truth is simpler. Write the sentence. Read it aloud. Cut what you would skip.</p>
"""


def preview_html() -> str:
    return """
<article>
  <h1>The quiet page</h1>
  <p>Write like nobody is watching. The page is a room with the door closed, and the only sound is the sentence you are still deciding.</p>
  <p>A good sentence <em>earns</em> its keep. A <strong>great</strong> one makes the next one inevitable.</p>
  <blockquote>Clarity is the courtesy you owe the reader.</blockquote>
  <p>The rest is craft:</p>
  <ul>
    <li>Cut the word you only wrote to sound clever</li>
    <li>Keep the one that still surprises you</li>
    <li>Stop when the thought is finished, not when the paragraph looks full</li>
  </ul>
  <p>That is enough. Close the file before you start explaining it.</p>
</article>
"""


def css(theme: dict, extra: str = "") -> str:
    return f"""
@font-face {{ font-family: "Duo"; src: url("/Resources/Fonts/iAWriterDuoS-Regular.ttf"); font-weight: 400; font-style: normal; }}
@font-face {{ font-family: "Duo"; src: url("/Resources/Fonts/iAWriterDuoS-Italic.ttf"); font-weight: 400; font-style: italic; }}
@font-face {{ font-family: "Duo"; src: url("/Resources/Fonts/iAWriterDuoS-Bold.ttf"); font-weight: 700; font-style: normal; }}
@font-face {{ font-family: "Duo"; src: url("/Resources/Fonts/iAWriterDuoS-BoldItalic.ttf"); font-weight: 700; font-style: italic; }}
@font-face {{ font-family: "Quattro"; src: url("/Resources/Fonts/iAWriterQuattroS-Regular.ttf"); font-weight: 400; font-style: normal; }}
@font-face {{ font-family: "Quattro"; src: url("/Resources/Fonts/iAWriterQuattroS-Italic.ttf"); font-weight: 400; font-style: italic; }}
@font-face {{ font-family: "Quattro"; src: url("/Resources/Fonts/iAWriterQuattroS-Bold.ttf"); font-weight: 700; font-style: normal; }}
* {{ box-sizing: border-box; }}
html, body {{
  margin: 0; padding: 0;
  background: {theme['stage']};
  -webkit-font-smoothing: antialiased;
}}
.stage {{
  width: var(--stage-w);
  height: var(--stage-h);
  display: flex;
  align-items: center;
  justify-content: center;
}}
.window {{
  width: var(--win-w);
  height: var(--win-h);
  background: {theme['bg']};
  border-radius: 10px;
  box-shadow: 0 24px 60px rgba(0,0,0,.22), 0 0 0 0.5px rgba(0,0,0,.12);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  position: relative;
}}
.titlebar {{
  height: 52px;
  flex: none;
  display: flex;
  align-items: center;
  position: relative;
}}
.dots {{
  display: flex;
  gap: 8px;
  padding-left: 20px;
  z-index: 2;
}}
.dot {{ width: 12px; height: 12px; border-radius: 50%; }}
.red {{ background: #FF5F57; }}
.yellow {{ background: #FEBC2E; }}
.green {{ background: #28C840; }}
.filename {{
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font: 13px/1 -apple-system, BlinkMacSystemFont, "SF Pro Text", system-ui, sans-serif;
  color: {theme['title']};
  pointer-events: none;
}}
.body {{
  flex: 1;
  display: flex;
  min-height: 0;
}}
.editor {{
  flex: 1;
  padding: 4px 24px 16px;
  overflow: hidden;
}}
.column {{
  max-width: 36em;
  margin: 0 auto;
  font-family: "Duo", ui-monospace, monospace;
  font-size: 17px;
  line-height: 1.5;
  color: {theme['text']};
}}
.column p {{ margin: 0 0 1.15em; }}
.column .h {{ font-weight: 700; margin-bottom: 1.35em; }}
.column em {{ font-style: italic; }}
.column strong {{ font-weight: 700; }}
.mk {{ color: {theme['markup']}; font-weight: 400; }}
.quote {{ }}
.li {{ margin: 0 0 0.15em !important; }}
.li.last {{ margin-bottom: 1.15em !important; }}
.stats {{
  height: 28px;
  flex: none;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding: 0 16px;
  font: 11px/1 ui-monospace, "SF Mono", Menlo, monospace;
  color: {theme['dim']};
}}
.noun {{ color: {theme['noun']}; }}
.verb {{ color: {theme['verb']}; }}
.adjective {{ color: {theme['adjective']}; }}
.adverb {{ color: {theme['adverb']}; }}
.conjunction {{ color: {theme['conjunction']}; }}
.focus .column, .focus .column p, .focus .column .mk, .focus .column em, .focus .column strong {{
  color: {theme['dim']};
}}
.focus .hot, .focus .hot * {{
  color: {theme['text']} !important;
}}
.caret {{
  display: inline-block;
  width: 2px;
  height: 1.05em;
  background: {theme['accent']};
  vertical-align: -0.15em;
  margin-left: 1px;
}}
.strike {{
  color: {theme['dim']};
  text-decoration: line-through;
  text-decoration-color: {theme['dim']};
}}
.sidebar {{
  width: 220px;
  flex: none;
  background: {theme['sidebar']};
  border-right: 0.5px solid {theme['rule']};
  padding: 8px 0 12px;
  font: 13px/1.4 -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
  color: {theme['text']};
}}
.search {{
  margin: 0 12px 10px;
  background: {theme['search']};
  border-radius: 6px;
  padding: 5px 8px 5px 24px;
  color: {theme['dim']};
  font-size: 12px;
  position: relative;
}}
.file {{
  padding: 5px 14px 5px 18px;
}}
.file.sel {{
  background: {theme['selected']};
}}
.preview {{
  flex: 1;
  border-left: 0.5px solid {theme['rule']};
  padding: 8px 36px 24px;
  overflow: hidden;
  font-family: "Quattro", -apple-system, sans-serif;
  font-size: 17px;
  line-height: 1.65;
  color: {theme['text']};
  background: {theme['bg']};
}}
.preview h1 {{
  font-size: 1.9em;
  font-weight: 700;
  line-height: 1.25;
  margin: 0 0 0.6em;
}}
.preview p {{ margin: 0 0 1.1em; }}
.preview blockquote {{
  margin: 1.2em 0;
  padding: 0 0 0 1.1em;
  border-left: 3px solid {theme['rule']};
  color: {theme['muted']};
}}
.preview ul {{ padding-left: 1.6em; margin: 0 0 1.1em; }}
.preview li {{ margin: 0.25em 0; }}
{extra}
"""


def page(theme: dict, inner: str, width: int, height: int, stage_pad: int = 56) -> str:
    sw, sh = width + stage_pad * 2, height + stage_pad * 2
    return f"""<!doctype html>
<html><head><meta charset="utf-8">
<style>
:root {{ --win-w: {width}px; --win-h: {height}px; --stage-w: {sw}px; --stage-h: {sh}px; }}
{css(theme)}
</style></head>
<body><div class="stage"><div class="window">{inner}</div></div></body></html>
"""


def chrome_bar(name: str) -> str:
    return f"""
<div class="titlebar">
  <div class="dots"><div class="dot red"></div><div class="dot yellow"></div><div class="dot green"></div></div>
  <div class="filename">{name}</div>
</div>
"""


def editor_shell(name: str, body: str, stats: str, extra_class: str = "", sidebar: str = "", preview: str = "") -> str:
    return f"""
{chrome_bar(name)}
<div class="body {extra_class}">
  {sidebar}
  <div class="editor"><div class="column">{body}</div></div>
  {preview}
</div>
<div class="stats">{stats}</div>
"""


SHOTS = []


def add(name: str, html: str, width: int, height: int) -> None:
    SHOTS.append((name, html, width, height))


add(
    "editor-light",
    page(LIGHT, editor_shell("the-quiet-page.md", heading() + prose(), "98 words · 1 min"), 760, 720),
    872,
    832,
)
add(
    "authorship-light",
    page(LIGHT, editor_shell("the-quiet-page.md", authorship(), "You 61% · 72 words · 1 min"), 760, 560),
    872,
    672,
)
add(
    "editor-dark",
    page(DARK, editor_shell("the-quiet-page.md", heading() + prose(), "98 words · 1 min"), 760, 720),
    872,
    832,
)
add(
    "syntax-dark",
    page(DARK, editor_shell("the-quiet-page.md", heading() + syntax_prose(), "98 words · 1 min"), 760, 720),
    872,
    832,
)
add(
    "focus-light",
    page(LIGHT, editor_shell("the-quiet-page.md", heading() + focus_prose(), "98 words · 1 min", extra_class="focus"), 760, 720),
    872,
    832,
)
add(
    "preview-light",
    page(
        LIGHT,
        editor_shell(
            "the-quiet-page.md",
            heading() + prose(),
            "98 words · 1 min",
            preview=f"<div class='preview'>{preview_html()}</div>",
        ),
        1180,
        720,
    ),
    1292,
    832,
)
add(
    "style-check",
    page(LIGHT, editor_shell("workshop.md", workshop(), "40 words · 1 min"), 760, 520),
    872,
    632,
)
add(
    "library-dark",
    page(
        DARK,
        editor_shell(
            "the-quiet-page.md",
            heading() + prose(),
            "98 words · 1 min",
            sidebar="""
<div class="sidebar">
  <div class="search">Search</div>
  <div class="file sel">The quiet page.md</div>
  <div class="file">Workshop.md</div>
  <div class="file">Notes.md</div>
</div>
""",
        ),
        980,
        720,
    ),
    1092,
    832,
)


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def log_message(self, format, *args):
        pass


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    shot_dir = ROOT / "docs" / "screenshots" / "_html"
    if shot_dir.exists():
        shutil.rmtree(shot_dir)
    shot_dir.mkdir()

    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    port = server.server_address[1]
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    threading.Event().wait(0.2)

    for name, html, w, h in SHOTS:
        rel = f"docs/screenshots/_html/{name}.html"
        (ROOT / rel).write_text(html, encoding="utf-8")
        dest = OUT / f"{name}.png"
        cmd = [
            CHROME,
            "--headless=new",
            "--disable-gpu",
            "--hide-scrollbars",
            "--virtual-time-budget=4000",
            "--force-device-scale-factor=2",
            f"--window-size={w},{h}",
            f"--screenshot={dest}",
            f"http://127.0.0.1:{port}/{rel}",
        ]
        subprocess.run(cmd, check=True, cwd=ROOT, capture_output=True)
        print(dest, dest.stat().st_size)

    server.shutdown()
    shutil.rmtree(shot_dir)


if __name__ == "__main__":
    main()
