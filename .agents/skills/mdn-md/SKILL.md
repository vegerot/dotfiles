---
name: mdn-md
description: Read MDN docs from mdn/content source markdown instead of fetching rendered pages. Use for any task that needs MDN article content, macro interpretation, front matter metadata, or URL-to-source translation.
references:
  - mdn-content
  - mdn-markdown
  - mdn-macros
---

# MDN Markdown Source Reading

**STOP.** If you are about to curl, fetch, or WebFetch an MDN article from developer.mozilla.org, read the source markdown instead.

## Rule

- Do not read the rendered MDN page first.
- Read the article's markdown source from `mdn/content` on GitHub instead at https://github.com/mdn/content/.
- Prefer the raw source URL, because it is smaller and usually contains the exact content you need.

## URL translation

- MDN pages live under `files/en-us/...` in `mdn/content`.
- Each page is usually an `index.md` file.
- The path mirrors the MDN slug.
- Lowercase the locale and path when mapping to the repo path.

Example:

- `https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Anchor_positioning/Using`
- `https://raw.githubusercontent.com/mdn/content/refs/heads/main/files/en-us/web/css/guides/anchor_positioning/using/index.md`

Translation steps:

1. Remove `https://developer.mozilla.org/`.
2. Drop the locale/docs prefix from the slug, keeping the content path.
3. Lowercase the remaining path segments.
4. Prefix with `files/en-us/`.
5. Append `/index.md`.
6. Use `https://raw.githubusercontent.com/mdn/content/refs/heads/main/...`.

## What to read

### Front matter

- The first block is YAML front matter between `---` lines.
- It is metadata for the build system.
- Common keys include `title`, `slug`, `short-title`, `page-type`, `browser-compat`, and `spec-urls`.
- Use it to confirm the canonical page name, page type, and related metadata before reading the prose.

### Markdown extensions

MDN uses GitHub-Flavored Markdown plus custom extensions.

- Macros: `{{ MacroName(...) }}`
- Alerts: `> [!NOTE]`, `> [!WARNING]`, `> [!CALLOUT]`
- Definition lists: nested list syntax with `- : description`
- Tables: GFM tables or HTML when needed
- Code fences: standard fences, sometimes with `-nolint`

Treat macros and other extensions as MDN syntax, not literal Markdown noise.

## Macro reading guide

- Macros are build-system helpers, not JavaScript.
- Examples: `{{ EmbedLiveSample("CSS-only method", "100%", "120") }}`, `{{htmlelement("select")}}`.
- Macro names are case-sensitive in source, though MDN tolerates some capitalization drift.
- Parameters are comma-separated.
- If there are no parameters, parentheses may be omitted.

## How to understand macros

1. Check the MDN macro docs, especially the commonly used macros page.
2. Follow the linked source file in the docs when available.
3. If needed, inspect the implementation in `mdn/rari` under `crates/rari-doc/src/templ/templs/...`.
4. Read parameters as positional arguments unless the docs say otherwise.

Common patterns:

- `htmlelement("select")` links to the HTML element reference for `<select>`.
- `cssxref(...)`, `domxref(...)`, `jsxref(...)`, `svgxref(...)`, `httpheader(...)`, and similar macros create locale-safe reference links.
- `EmbedLiveSample(...)` embeds a live sample from the page's sample blocks.

## Workflow

When asked about an MDN page:

1. Convert the page URL to the raw GitHub markdown URL.
2. Read the `index.md` source.
3. Inspect front matter first.
4. Read prose, then decode any macros using the MDN docs or rari source.

## If you need more detail

- Use the MDN writing docs for markdown conventions and macro behavior.
- Use the macro source code when the docs do not fully explain a macro's parameters or output.
