---
name: plan-progress
description: Set up a plan.md and progress.md handoff convention in a new project. Use when asked to introduce these files or this convention.
---

# Set up plan and progress

Introduce a durable plan and an append-only progress handoff. Inspect the project's README, agent instructions, and planning documents first. Use its existing documentation layout: an established README or goal document can serve as the plan instead of adding a duplicate `plan.md`.

- **Plan:** Record the actual goal, settled constraints and decisions, intended work, and how completion will be judged when that is known. Link the evidence behind important decisions. Keep mutable status out of the plan.
- **`progress.md`:** Start an append-only log with dated entries, newest last. Each entry summarizes actions, outcomes, checks, blockers or open questions, and ends with a concrete `Next:` block. Use one relevant emoji per action summary. Keep commit IDs, transient status, and other changing state here. For consequential findings, state what was directly verified, the scope of the check, and what remains inferred or unverified. Link detailed evidence instead of copying it into the log; append corrections rather than rewriting old entries.

Put the resume convention in the plan or existing agent instructions: read the plan, then the newest progress entries; check the working copy and relevant live state against the handoff. Link the documents from the project's usual entry point. Write the initial plan from what the project actually knows and an initial progress entry for the setup and current state. Do not invent decisions, completed work, or authorization for a next phase.

Add structure only when the project needs it: layers, phases, or tracks for meaningful work stages; explicit completion or stop gates when the user has set them; assumptions and deferred work when they affect decisions; separate experiment or review records when evidence is too detailed for the plan or log. Make these project-specific rather than default rules.
