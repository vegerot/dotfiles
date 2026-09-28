---
name: five-step-engineering-algorithm
description: Apply Elon Musk's 5-step engineering and design algorithm to critique, optimize, or troubleshoot engineering systems, technical requirements, and production workflows. Use when users ask to apply the 5-step algorithm, simplify engineering architectures, eliminate unnecessary parts/processes, or evaluate technical designs.
---

# Five-Step Engineering Algorithm

Apply the 5-step design, engineering, and manufacturing process articulated by Elon Musk during SpaceX and Tesla production ramps, adapted for software engineering and systems architecture. This framework prevents common engineering traps—most notably optimizing systems that should not exist.

## When to Use

- Critiquing or refactoring software architecture, service boundaries, or deployment pipelines
- Reviewing RFCs, PRDs, engineering design documents, or technical specs
- Auditing bloated processes, CI/CD pipelines, manual review gates, or redundant test suites
- Evaluating feature bloat, dead code paths, or unnecessary dependencies

---

## The 5 Steps (Execute in Strict Order)

Never invert or skip steps. Steps 1 through 3 determine whether a component or requirement should exist; Step 4 accelerates it; Step 5 automates it.

### 1. Make Requirements Less Dumb
- **Premise:** All requirements are fundamentally flawed to some degree. It is especially dangerous when requirements come from someone intelligent or authoritative, as people tend not to question them. Question the question.
  - *Context note:* The "intelligent and authoritative" source is frequently the user or author prompting you. Be constructively skeptical and critically evaluate their premises and constraints.
- **Rule of First Principles:** Every requirement, constraint, or acceptance criterion must be challenged against first principles. Ask: *Why are we doing this? What is the actual goal? What core problem are we trying to solve for the user or customer?*
- **User Obsession:** Every requirement must be evaluated against the end user's needs and goals. If an engineering constraint or feature exists solely for internal convention, architectural vanity, or hypothetical edge cases without directly serving the user, question or eliminate it.
- **Rule of Ownership (Optional):** Every requirement or constraint should ideally have an assigned person's name attached, never an anonymous department, team, or committee. When an owner can't be found and there is no obviously good reason for a requirement, assume the constraint is obsolete. A department cannot take responsibility or answer questions. (This rule is optional and may be ignored if organizational ownership tracking is not applicable.)
- **Action:**
  - Challenge every assumption directly against first principles.
  - Ask: *What fundamental law of physics, engineering invariant, or user outcome breaks if we remove this?*
  - Reject anonymous legacy rules, historical hand-me-downs, and speculative constraints.

### 2. Delete the Part or Process Step
- **Premise:** Human bias leans toward adding parts, checks, or steps "just in case." You can justify almost anything with an "in-case" argument.
- **The 10% Rule:** If you are not adding deleted elements back at least 10% of the time, you are not deleting aggressively enough.
- **Action:**
  - Remove components, microservices, abstraction layers, defensive wrappers, intermediate configs, or manual approval steps.
  - Favor simple, persistent mechanics over complex active coordination (e.g., favoring stateless request-reply or idempotent retries over distributed transactions, 2PC, and stateful background synchronization daemons).
  - Challenge intermediate testing: delete redundant in-process integration assertions or intermediate staging environments once robust end-to-end integration and canary verification demonstrate high reliability.

### 3. Simplify or Optimize
- **Premise:** The most common error of a smart engineer is optimizing something that should not exist in the first place. This stems from academic conditioning that rewards answering the prompt rather than questioning the premise.
- **Rule of Sequencing:** Never optimize prior to questioning requirements (Step 1) and attempting deletion (Step 2).
- **Action:**
  - Simplify only what survived deletion.
  - Minimize interfaces, reduce component count, reduce degrees of freedom, and tighten contracts only where necessary.
  - Piggyback on existing runtime capabilities rather than adding dedicated infrastructure (e.g., tapping into database Write-Ahead Logs / CDC or existing HTTP/2 multiplexed streams instead of spinning up and maintaining a separate message broker cluster like Kafka or RabbitMQ).

### 4. Accelerate Cycle Time
- **Premise:** Work moves too slowly, but speeding up an unvalidated process is simply digging a grave faster.
- **Action:**
  - Accelerate feedback loops, iteration cycles, and build/deploy pipelines only after steps 1 through 3 are complete.
  - Identify the active bottleneck on the critical path (e.g., slow test runs, bloated Docker build contexts, serial linting) and shorten turnaround intervals.

### 5. Automate
- **Premise:** Automation belongs strictly at the end. Automating an unsimplified or unnecessary process locks in waste and multiplies complexity.
- **Action:**
  - Only automate workflows, tests, and deployment steps after the process has been pruned, simplified, and accelerated.
  - Avoid automating edge cases or fragile workflows that can be bypassed or eliminated entirely.

---

## Overarching Principle: Everyone is Chief Engineer

- Every engineer must maintain high-level visibility across the complete system.
- Avoid local micro-optimizations that create net systemic drag (e.g., spending weeks hand-optimizing a JSON serializer in C++ or Rust to shave 2 ms while an unindexed N+1 SQL query over a cross-region connection wastes 1,200 ms).
- Reject organizational silos: understanding the full stack prevents teams from solving the wrong problem.

---

## Audit Checklist

When reviewing a design, feature, or pipeline, evaluate against this table:

| Step | Question | Red Flag |
| :--- | :--- | :--- |
| **1. Requirements** | What core user problem does this solve? What breaks if we reject the author's/prompt's premise? | Uncritical deference to authority; solving for internal vanity or speculative edge cases rather than user value; legacy rules without an owner. |
| **2. Deletion** | Can this service, abstraction layer, or intermediate step be removed entirely? | "We might need this later"; speculative "in-case" features and defensive wrapper layers. |
| **3. Simplification** | Is this the minimal viable implementation of what survived? Can existing primitives handle this? | Over-engineered design patterns; introducing heavy standalone infrastructure for simple tasks. |
| **4. Acceleration** | Where is the critical path bottleneck? How do we shorten the feedback loop? | Long CI runs; batching updates across days instead of shipping small iterations in minutes. |
| **5. Automation** | Is this process lean and stable enough to automate? | Scripting or building complex automation around an unstable, redundant, or unpruned workflow. |

---

## Source

- [Starbase Tour with Elon Musk](https://youtu.be/t705r8ICkRw?t=802)
