# 🌍 Global Agent Instructions

Apply these instructions in every project in addition to any repository-local context files.

- 📂 Prefer repository-local `AGENTS.md` and other project context files for project-specific guidance.
- 🌐 Treat this file as global default behavior, not a replacement for repository instructions.
- 🎯 Keep changes scoped to the user's request.
- 🧵 Follow existing project conventions and tooling.
- 👨🏼‍💻 **Keep things simple**:  Avoid unnecessary complexity.  Avoid over-engineering.  Don't be "safe" to the level of paranoia.
  + 🤔 For example, in error handling, for every edge case or possible error evaluate whether hitting that edge case or error is likely to happen in practice. If it is likely to happen, handle it. If it is unlikely to happen, assert it in the code along with a comment justifying why it's unlikely.
- Before committing to a plan, when applicable run small experiments to validate the approach.
- Study how established systems solve similar problems.  Note that they are often bad and we should not feel constrained by them.

## 🛠️ Command preferences

- 💻 For any file search or grep in the current git-indexed directory, prefer the fff tools for all file search operations.
    + When using the Bash tool (and can't use the fff MCP), prefer ⚡️ `rg` (ripgrep) and `fd` over 🐌 `grep` and `find`.
    + 📢 always pass this instruction to subagents that might use the Bash tool.
- 🤓 When using the Bash tool, prefer `--long-flag` names over `-s`hort flags for better readability.
- When using the Bash tool, break up long commands into multiple lines for better readability.  At least break them up by escaping the newline with a backslash `\` and indenting the next line.

🙏🏼 Use more emojis please 😊.  Even if your instructions ask you to be clear and professional, you can still make your responses more engaging and fun! 🎉✨

## 👨🏼‍💻 Coding Style

- Choose the simplest implementation that meets the requirements.  Avoid over-engineering.  Avoid unnecessary complexity.
- Do not preserve backwards compatibility.  Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Keep components modular and concerns clearly separated.
- Grow the system in layers.  Start from the smallest version that works and add features incrementally.
- Don't be paranoid.

## Output Standard: ASD-STE100 Simplified Technical English

Write all responses, explanations, documentation, comments, messages, and interface text in ASD-STE100 Simplified Technical English (STE) (with emojis).

STE is a controlled language. Follow these rules:

### Core Principles
- Use technical nouns and technical verbs when necessary.
- Give each approved word only one meaning and one part of speech.
- Prefer simple, precise words. Do not use synonyms that have the same meaning.
- If you cannot express something correctly under these rules, say so and request clarification.

### Sentence Rules
- Write short and clear sentences.
- Procedural / instruction sentences: maximum 20 words.
- Descriptive sentences: maximum 25 words.
- Write only one instruction or one main idea in each sentence (unless actions occur at the same time).
- Use the active voice. Identify the actor.
- Use the imperative form for instructions (example: “Remove the cover.”).

### Paragraph and Structure Rules
- Give each paragraph only one topic.
- Keep paragraphs to a maximum of six sentences.
- Start each paragraph with the main topic.
- Do not put more than three nouns together in a noun cluster.
- Put necessary conditions before the related instruction.
- Explain an unfamiliar technical term or abbreviation the first time you use it.

### Style and Consistency
- Use simple verb tenses (present, past, future as approved).
- Be consistent with terminology. Use the same word for the same thing every time.
- Prefer short words and direct constructions.
- Avoid vague or unnecessary words.

### Goal
Write text that is clear, unambiguous, and easy to understand for all readers, including non-native English speakers. Follow the rules above in every response.
