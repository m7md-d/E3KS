<img src="brand/e3ks-icon.svg" alt="" width="88" align="left" hspace="12">

# E3KS

**Colour and font replacement for Office documents.** A macOS desktop app that
re-skins the visual identity of `.docx` and `.pptx` files without corrupting
them.

<br clear="left">

---

## The problem

An organisation changes its brand. Its existing documents do not. A single
Word file carries the old palette in the body, the headers, the footers, the
footnotes, the table styles, the numbering definitions and the theme part —
and the old typefaces in four separate attributes per run, one of which
(`w:cs`) is the only one that affects Arabic text.

Find-and-replace does not reach any of it. Doing it by hand means opening
every style and every table. Scripting it with a general-purpose XML library
usually works until it doesn't: re-serialising a part that was never edited
changes attribute quoting, entity encoding and whitespace, and some importers
reject the result. The failure often shows up somewhere other than Word —
Google Docs is stricter — which means it shows up after the file has been
sent.

E3KS does the substitution and leaves everything else exactly as it found it.

## What it does

**Inspect** — lists every colour and font in the document with its occurrence
count, its role (text, paragraph fill, cell fill, border, shape fill, theme
palette…), the parts it appears in, and a sample of the text it is applied to.
Colours that belong to the content are separated from colours inherited from
built-in Office templates; in a real document the inherited set can be most of
the total and is rarely what anyone wants to change.

**Preview** — renders pages at their real size, taken from the document
(`w:sectPr/w:pgSz` and `w:pgMar`), not sized to their content. Slides are laid
out from the declared shape geometry (`a:xfrm`), including placeholders that
inherit their position from the slide layout. Before/after is a toggle. Line
breaking is not simulated: what the document declares is what gets drawn, and
where a page would overflow, the sheet extends and its true edge is marked
rather than clipping content out of sight.

**Map** — assign a replacement per colour, or apply a saved identity. Colours
can be picked three ways: click one on the page, click the swatch in the list,
or use the eyedropper in the preview toolbar, which samples the rendered
pixels and resolves them to a colour the document actually declares. A tracked
colour is highlighted wherever it appears and can be stepped through page by
page. Each colour also offers a nine-step tonal ramp computed from itself.

**Identities** — a named set of colours and fonts, stored as readable JSON, and
applicable to any document. An identity can also be extracted from another open
file: its colours ordered by use, labelled where a role can be inferred.

**Fonts** — the preview needs the document's fonts to be honest about how it
looks. Resolution order is bundled → installed on the machine → previously
cached → fetched from Google Fonts. Only the font name leaves the machine, and
fetching can be switched off. Whatever is fetched is listed in settings with
its size and can be deleted. Monospaced fonts are excluded from replacement by
default, because substituting them breaks the alignment of code blocks.

**Export** — the output is validated before anything is written. If validation
fails, no file is produced and the reason is reported.

Interface is Arabic and English; layout direction follows the language.

## Fidelity

The guarantee is at the level of the part, not the archive:

- Parts that were not modified are copied byte for byte. XML that was not
  changed is never re-serialised.
- Entity encoding matches what Word writes (`&gt;` rather than a literal `>`),
  so a parse/serialise round trip of an edited part is byte-identical to its
  input. Measured across 4 documents and 78 parts.
- The only accepted difference in the ZIP envelope is the dropped `0xA220`
  Open Packaging Growth Hint field, which carries no document meaning.
- Explicit colour changes also remove the `w:themeColor` / `*Theme` attributes
  on the same element, otherwise the theme value can win in some importers and
  the old colour comes back.
- Dynamic fields (`PAGE`, `TOC`, `REF`) are not written into. The stored result
  inside a field is a cached value, and overwriting it freezes page numbers.
- No `<w:t>` element is ever emitted without a text node. It is schema-valid
  and Word opens it, but the Google Docs importer dereferences null on it.
- Each format declares the parts it owns, and the pipeline enforces the
  declaration: a write outside it aborts the export. So a bug in the PowerPoint
  path cannot reach `word/`.
- Writes are atomic — temporary file then rename. The source is opened
  read-only.

Validation before every write checks: all XML parses, zero empty text nodes,
balanced field characters, `[Content_Types].xml` present and first in the
archive, output part count equal to input, every relationship target present,
and the finished archive re-opens and reads back.

## Formats

| Format | Status |
|---|---|
| `.docx` — Word | Supported |
| `.pptx`, `.ppsx`, `.potx` — PowerPoint | Supported |
| `.pdf` | Researched only. Colours look feasible, fonts do not. |

Detection is by content type, not file extension, so a renamed file is handled
as what it is.

Not implemented on slides: images and charts are not drawn in the preview
(text, fills and borders are), and speaker notes are inspected but not shown.

## Built with

| | |
|---|---|
| Language | Dart 3.9+ |
| UI | Flutter (macOS desktop) |
| Archive / XML | `archive`, `xml` |
| Files | `file_selector`, `desktop_drop` |
| Icons | `lucide_icons_flutter` |
| Localisation | `flutter_localizations`, `intl`, ARB files |
| State | `ChangeNotifier` and `ListenableBuilder` — no state framework |
| UI font | IBM Plex Sans Arabic, bundled |

The engine is pure Dart with no Flutter dependency, so it runs under
`dart test` in seconds and can be reused on other platforms.

## Layout

```
packages/e3ks_engine/     Engine — inspect, transform, preview, validate
  lib/src/format/         Everything format-specific; nothing outside knows a format name
apps/e3ks_desktop/        Flutter UI. No transformation logic.
tools/e3ks_cli/           Command line over the engine
docs/adr/                 Architecture decision records
brand/                    Mark and its usage rules
.claude/rules/            Project rules (Arabic)
```

## Building

```bash
# Engine
cd packages/e3ks_engine && dart pub get && dart test

# App
cd apps/e3ks_desktop && flutter pub get && flutter run -d macos

# Release build, with the icon generated from brand/
./brand/build-appicon.sh
cd apps/e3ks_desktop && flutter build macos --release
```

Current state: 71 engine tests and 85 app tests. Phases 1–3 (engine, macOS
app, PowerPoint) are done; document metadata is next, on a separate path from
the styling pipeline.

Documentation and project rules are written in Arabic. Code identifiers are
English.

## Licence

```
E3KS
Copyright (C) 2026  m7md-d
```

Free software under the **GNU General Public License, version 3** or any later
version, as published by the Free Software Foundation. Distributed in the hope
that it will be useful, but **with no warranty** — not even the implied
warranty of merchantability or fitness for a particular purpose. Full text in
[`LICENSE`](LICENSE).

### Third party

| | Licence |
|---|---|
| **IBM Plex Sans Arabic** — bundled UI font | SIL Open Font License 1.1, text in [`apps/e3ks_desktop/assets/fonts/OFL.txt`](apps/e3ks_desktop/assets/fonts/OFL.txt) |
| **Lucide** — UI icons | ISC |
| Dart and Flutter packages | Listed in the app under Settings → Licences |

Document fonts fetched from Google Fonts remain under their own licences and
are not redistributed; they are stored on the user's machine only.
