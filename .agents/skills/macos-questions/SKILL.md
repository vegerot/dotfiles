---
name: macos-questions
description: Answer questions about how macOS, Apple frameworks, Xcode, or Apple developer APIs work, using Apple's developer documentation (the bundled `appledocs` search) and the local Apple source checkouts under `~/code/github.com/apple/`. Use whenever asked how a macOS/iOS feature, API, daemon, setting, or Apple tool behaves, what Apple intends or documents, or why the system does something.
---

Answer macOS questions from three sources, and keep them apart in the answer: what Apple **documents**, what the **source** does, and what **this machine** actually does.

## 1. 📚 Apple's documentation: `appledocs`

`scripts/appledocs` (next to this file) is a semantic search over Xcode's offline Apple Developer Documentation RAG. It is a single file Swift executable, so you can inspect and edit it if you need to.

```sh
scripts/appledocs --k 5 "read file metadata without downloading a dataless iCloud file"
scripts/appledocs --framework FileProvider --k 5 "free up disk space by removing local copies"
```

- Output: one JSON line per hit with `score`, `title`, `uri`, `framework`, `kind` and the first 600 characters of `content`. Prepend `https://developer.apple.com` to `uri` to cite the page. `--framework` takes the exact name stored in the index (`FileProvider`, `Foundation`, `AVFoundation`, …).
- Use it for intended behavior, guarantees, tech notes (`TN…`) and API contracts. Ask in natural language. Run 2–3 phrasings when the first misses. Semantic search can miss an exact symbol (for example "evict a downloaded item" does not rank `evictItem`), so check symbol names with the keyword search below.
- Scores: useful hits score about 0.55–0.7. If every result is around 0.15 or lower and off topic, the embedding model no longer matches the index. Try `--version 11`, then fall back to keyword search.
- Keyword search (exact strings, symbol names):
  ```sh
  DB=$(ls -t /System/Library/AssetsV2/com_apple_MobileAsset_AppleDeveloperDocumentation/*.asset/AssetData/documentation-db/index.sql | head -1)
  sqlite3 -readonly "file:$DB?immutable=1" \
    "select json_extract(document,'$.uri') from documents where document like '%evictItem%' limit 10"
  ```
- No index on disk? Ask the user to install it from Xcode ▸ Settings ▸ Components ▸ Developer Documentation.

How it works: the query is embedded by the macOS media-analysis daemon (private `MADTextEmbeddingRequest`, version 10 = the config's `md8`), then compared by cosine with every vector in the newest asset's `index.sql`. Details, measurements and diagrams: `~/ai-conversations/macos/README.md` and the "Xcode Doc Index Anatomy" artifact (https://claude.ai/artifact/LWCtC2uV1DkG435gG7Cpqa). It relies on private APIs, so a macOS update can break it. If it breaks, record the fix there.

## 2. 🧩 Apple's source: `~/code/github.com/apple/`

1. Read `~/code/github.com/apple/AGENTS.md` first.
2. Search **at least two directory levels deep**. The `distribution-*` repos (`distribution-macOS`, `distribution-Developer_Tools`) are collections of submodules, so their top level hides the implementation.
  - Compare the checked-out tag with `sw_vers`, and say in the answer when the source is older than the running OS
3. Closed-source parts: inspect the binaries. System frameworks live in the dyld shared cache (`/System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/`), and Xcode's live in `Xcode.app/Contents/{PlugIns,SharedFrameworks}` (`strings`, `otool -L`, Objective-C runtime introspection).

Use the source for the **mechanism**: why the docs' promise holds, edge cases, and undocumented behavior.

## 3. 🔬 This machine

Documentation and source give options and defaults in general, not this Mac's values. Measure machine-specific facts locally (`defaults read`, `sw_vers`, a small C/Swift probe, real runtime behavior) before stating them. Example: the default `say` voice was Samantha at 175 wpm, measured with `NSSpeechSynthesizer`.

## Answer shape

Lead with the answer. Cite the doc page (`uri`) and the source path (`file:line`). Label each claim as documented, read in source, measured, or inferred.
