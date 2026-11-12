---
name: web-coding-style
description: Personal style rules for web code — semantic HTML, hand-written modern CSS, browser JS, and TypeScript. Use when writing, editing, or reviewing HTML, CSS, JSX, or browser-side JS/TS.
---

# 🌐 Web coding style

The repository's own instructions and existing conventions win over this skill.

Other skills and guides decide *which* platform feature to use; this skill decides how much JS and how the code is written. When they disagree, follow this skill.

## 🏷️ HTML

- Prefer semantic elements (`header`, `nav`, `main`, `section`, `article`, `figure`, `ul`, `footer`, `address`, …). Use `div` / `span` only when no semantic element fits.
- Avoid wrapper elements that exist only for styling; Flex, Grid, or adjacent selectors usually do the job.
- Rely on built-in semantics instead of redundant ARIA (a `<button>` needs no `role="button"`).
- Prefer native form controls and native form validation over custom components.
- Use `loading="lazy"` for below-the-fold images instead of lazy loading in JS.
- For interactive UI, prefer this order:
  1. A native element or attribute: `<details>`, `<dialog>`, `popover`, form validation.
  2. CSS: `:has()`, `:checked`, `transition`, …
  3. JavaScript, only when 1 and 2 can't do it.

## 🎨 CSS

- 📱 **Every feature must be responsive on both desktop and mobile.**
- Follow the project's existing styling approach. When you write CSS by hand, use the rules below, and don't invent a utility-class mini-framework.
- Units: prefer `rem` by default. Use `%`, `vw`, `dvh`, `ch`, or `rlh` where they express the intent better (e.g. `rlh` for sizes tied to the line height). Avoid `px` unless it's the most idiomatic unit: sizes that shouldn't grow with the user's font size (e.g. `1px` hairline borders).
- Colors: write `oklch()` or CSS named colors (`black`, `white`, `transparent`, `currentColor`). Never hex, `rgb()`, or `hsl()`.
- Prefer native CSS nesting.
- Put repeated values in custom properties: z-index layers (always), gutters, brand colors. `var()` does not work in `@media` conditions, so don't use it for breakpoints.
- Prefer modern native CSS over JS: `:has()`, `:is()`, `:where()`, container queries, `min()` / `max()` / `clamp()`, `aspect-ratio`.
- Prefer `gap` over margins in Flex and Grid layouts.
- Use `transition` for simple state changes; save `@keyframes` for complex motion.
- Prefer minimal, targeted base styles over large resets.
- Group properties in this order, with a blank line between groups. Put an unlisted property in the closest group.
  1. **Layout:** `position`, inset, `z-index`, `display`, flex/grid, size, `margin`, `padding`, `gap`, `overflow`
  2. **Text:** `font-*`, `line-height`, `color`, `text-*`, `white-space`
  3. **Appearance:** `background`, `border`, `border-radius`, `box-shadow`, `opacity`, `list-style`
  4. **Behavior:** `transition`, `animation`, `cursor`, `pointer-events`, `user-select`

❌ Fixed `px` sizes, a hex color, a magic z-index, no nesting, no groups:

```css
.mobile-menu nav {
	position: fixed;
	top: 56px;
	left: 0;
	width: 631px;
	height: calc(788px - 56px);
	background: #000000;
	padding: 32px 10px;
	display: flex;
	flex-direction: column;
	gap: 24px;
	z-index: 9;
	overflow-y: auto;
}
```

✅

```css
.mobile-menu {
	nav {
		position: fixed;
		inset-block-start: 4rem;
		inset-inline-start: 0;
		z-index: var(--nav-menu-layer);
		display: flex;
		flex-direction: column;
		inline-size: 100vw;
		block-size: calc(100dvh - 4rem);
		padding: 2rem var(--gutter);
		gap: 1.5rem;
		overflow-y: auto;

		background: black;
	}
}
```

## 🌐 Browser JS

- Prefer native web APIs (`Intl`, `URL`, `FormData`, built-in array methods) first, then packages the project already depends on, then new dependencies.
- Start with local component state; use shared global state only when state truly travels across distant parts of the app.

## ⚙️ TypeScript

- Don't create reusable utilities, hooks, or abstractions for logic used only once.
- Prefer flat logic: early returns, no deeply nested ternaries, complex conditions stored in named variables.
- No `any`. Use `unknown` only for truly unknown input (e.g. parsed JSON) and narrow it right away. Prefer to avoid `as` unless the type system can't express the fact.
- Before adding a dependency, ask "can simple native code do this?" (lodash almost never passes).
