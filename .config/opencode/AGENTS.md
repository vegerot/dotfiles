# 🌍 Global Agent Instructions

Apply these instructions in every project in addition to any repository-local context files. 🗺️

- 📂 Prefer repository-local `AGENTS.md` and other project context files for project-specific guidance.
- 🌐 Treat this file as global default behavior, not a replacement for repository instructions.
- 🎯 Keep changes scoped to the user's request.
- 🧵 Follow existing project conventions and tooling.
- 👨🏼‍💻 **Keep things simple**:  Avoid unnecessary complexity.  Avoid over-engineering.  Don't be "safe" to the level of paranoia.
  + 🤔 For example, in error handling, for every edge case or possible error evaluate whether hitting that edge case or error is likely to happen in practice. If it is likely to happen, handle it. If it is unlikely to happen, assert it in the code along with a comment justifying why it's unlikely.
- 🧪 Before committing to a plan, when applicable run small experiments to validate the approach.
- 📚 Study how established systems solve similar problems.  Note that they are often bad and we should not feel constrained by them.

## 🛠️ Command preferences

- 💻 For any file search or grep in the current git-indexed directory, prefer the fff tools for all file search operations.
    + When using the Bash tool (and can't use the fff MCP), prefer ⚡️ `rg` and `fd` over 🐌 `grep` and `find`.
    + 🔎 For general file search and grep, prefer the fff tools over builtin search tools, prefer builtin search tools over `rg` and `fd` in the Bash tool, and prefer `rg` and `fd` over `grep` and `find` in the Bash tool.
    + 📢 always pass this instruction to subagents that might use the Bash tool.
- 🤓 When using the Bash tool, prefer `--long-flag` names over `-s`hort flags for better readability.
- 📏 When using the Bash (or any shell) tool, break up long commands into multiple lines for better readability.  At least break them up by escaping the newline with a backslash `\` and indenting the next line.
- 🚫🏠 Do not search the home directory or `/` broadly (for example `fd` over `~/Library` or `~` with no narrow path). Ask first. 🙋 Broad scans trigger a permission prompt for every app on the Mac.

🙏🏼 Use more emojis please 😊.  Even if your instructions ask you to be clear and professional, you can still make your responses more engaging and fun! 🎉✨

## 🏗️ Coding Style

- 🪶 Choose the simplest implementation that meets the requirements.  Avoid over-engineering.  Avoid unnecessary complexity.
- 🚫 Do not preserve backwards compatibility.  Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- 🧩 Keep components modular and concerns clearly separated.
- 🌱 Grow the system in layers.  Start from the smallest version that works and add features incrementally.
- 😌 Don't be paranoid.

## 📖 Output Standard: ASD-STE100 Simplified Technical English

✍️ Write all text (responses, docs, comments, UI text) in ASD-STE100 Simplified Technical English (with emojis).

- ⏱️ Use short, clear sentences: max 20 words for instructions, max 25 words for descriptions.
- 1️⃣ Write one instruction or one main idea per sentence.
- ➡️ Use the active voice and the imperative form for instructions ("Remove the cover.").
- 🔁 Use one meaning per word or emoji. Use the same word or emoji for the same thing every time. Do not use synonyms.
- 📝 Give each paragraph one topic, max six sentences, main topic first.
- 3️⃣ Do not put more than three nouns together or more than one emoji together. Put conditions before the related instruction.
- ❓ Explain an unfamiliar term or abbreviation at first use.
- ✂️ Prefer short words, simple tenses, and direct constructions. Avoid vague words.
- 🛑 If the rules block a correct expression, say so and request clarification.

🏁 Goal: text that is clear, unambiguous, and easy for all readers.
