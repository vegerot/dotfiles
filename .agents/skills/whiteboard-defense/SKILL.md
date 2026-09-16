---
name: whiteboard-defense
description: Quiz and teach me how an existing project or feature works through a rigorous, evidence-backed whiteboard interview. Use when I want to understand, explain, or defend a system I work on.
---

# Whiteboard defense

Help the user build a mental model they can explain without looking at the code. Inspired by [Mitchell Hashimoto's whiteboard defense](https://x.com/mitchellh/status/2100249348345057389): someone shipping a customer-facing system should be able to explain how it works, why key choices were made, what happens when things go wrong, and where it fails. Exact function names and line-level recall are not the goal.

## Set up the interview

- Use the project, feature, or repository the user names. If none is named, use the current project and identify a meaningful observable behavior to trace. Ask the user to choose only if several paths are equally plausible and the choice changes the interview.
- Inspect the relevant project instructions, docs, code, and tests enough to trace that path before judging answers. Prefer a small, real example over an exhaustive repository tour. Keep reading as the interview reveals gaps.
- Ask what the user already believes the system does and how a request or action travels through it. Let them answer before presenting your model. Calibrate the depth to their role and familiarity.

## Run the session

Ask **one substantive question at a time** and wait for the answer. Start with the user's experience and a concrete end-to-end flow, then follow the dependencies and decisions that matter most. Draw from these angles as applicable:

- Who uses it, what outcome do they need, and what are the system boundaries?
- What starts the flow, which components exchange data, and where does state live?
- What invariants or data structures make the behavior work? Why choose this approach over a plausible alternative?
- What happens under invalid input, partial failure, concurrency, retries, or a malicious actor? Where does the system fail or degrade?
- What evidence shows the intended behavior: tests, documentation, code paths, observed output, or recorded design decisions?

Press on vague claims with a specific scenario or counterexample. Vary the angle instead of repeating a question. Be demanding about reasoning and clear about uncertainty, without turning the session into trivia or a hostile performance. Do not ask the user to memorize names, lines, or incidental implementation details.

After each answer, say what is correct, what is incomplete or unsupported, and why it matters. Ground corrections in the project with concise file references or other evidence. Distinguish observed behavior, documented intent, and your inference. If the reason for a decision is not recorded, say so; explore possible tradeoffs without presenting a guessed rationale as fact. Give a short explanation or walkthrough for a gap, then ask the user to apply it to a new scenario before moving on. If an answer reveals a project defect, distinguish that finding from a knowledge gap.

Maintain a small running map of what the user can explain and what still needs work. When they ask to stop, or the important paths are covered, summarize the system in plain language, the decisions they can defend, the remaining gaps, and the best next exercise. Do not declare mastery from one correct answer. For prototypes or experiments, keep the exercise proportional to their purpose; focus the full defense on work meant to be relied on by users.

This is a read-only learning session unless the user also asks for project changes. Do not write answers for the user before they attempt them.
