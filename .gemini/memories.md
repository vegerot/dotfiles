# 🧠 User Memory Profile (Max Coplan)

Durable context consolidated from `memories.md`. Repository-local `AGENTS.md` / `CLAUDE.md` files always take precedence over these defaults.

## 👤 Identity & Background
- **Name**: Max Kronrad Mendel Coplan (goes by **Max**). Born December 16, 1997.
- **Handles & Accounts**: GitHub `vegerot` (`https://github.com/vegerot`), ByteDance username `max.coplan`, personal email `max.k.coplan@gmail.com`.
- **Location & Timezone**: Sunnyvale, California (South Bay; relocated Dec 2021). Timezone: `America/Los_Angeles` (Pacific Time).
- **Languages**: Native English speaker; actively learning Hebrew; does not speak Chinese.
- **Identity & Interests**: World-class software engineer. Loves coding and learning about technology in his free time.  Jewish atheist. Deeply researches 20th-century European history (Weimar Germany, the Third Reich, the Holocaust; completed Richard J. Evans's *Third Reich* trilogy and corresponded with Evans; Dan Stone's *The Holocaust: An Unfinished History*), Jewish & modern Israeli history (*Unpacking Israeli History* podcast quizzes), LLM architecture & inference economics (MoE, KV cache, post-training, coding-agent internals), graphics/OS internals, astrophysics, and evolutionary biology.
- **Education**: B.S. in Physics (Astrophysics focus) with a Computer Science minor from Towson University (2015–2019). Undergraduate research simulated black-hole interiors in Mathematica; Wolfram Student Ambassador and physics tutor.
- **Gaming & Media**: Favorite and most-played games by far are *Super Smash Bros. Melee* (via Slippi) and *Halo*. Also plays/mods *DOOM* source ports (*Crispy Doom*) and *DOOM: The Dark Ages*, *Black Mesa*, *Beat Saber* (Meta Quest 2), *Mario Kart Wii* (*Retro Rewind* in Dolphin), *Pokémon Yellow* (`gen1recomp`), and co-op games with Mina.

## 🤝 Recurring People
- **Mina (Gilbi Mina Averbuch)**: Partner/girlfriend. Israeli, fluent in Hebrew and Russian, expert chef (Max notes he is bad at cooking), and co-op gaming partner. Planning a winter trip to Israel together (late Dec 2026 – mid-Jan 2027: Tel Aviv, Haifa, Jerusalem, Eilat; Google Drive project `"טיול חורף בישראל 🇮🇱 2026–2027"`).
- **Family**: Mother **Lisa Block Coplan**, father **Michael Coplan**, sister **Dori Coplan** (based in Lebanon, PA).
- **TikTok / ByteDance Colleagues**: Manager **Cong**; skip-level leadership **Yuntao**; mentees/colleagues **Emily** (mentored on ELMO), **Guoqing** (onboarded/mentored).

## 💼 Profession & Career History
- **Core Expertise**: Senior/Lead Software Engineer specializing in performance engineering, developer tooling, full-stack web infrastructure, and AI coding agents.
- **TikTok / ByteDance** (Nov 2024–present, `i18n_ecom_fe` group, GEC business line, San Jose/Sunnyvale):
  - **Project Phoenix**: Championed and led from-scratch Seller Center homepage rewrite, cutting LCP from 13s to 1.5s (9x).
  - **ELMO (Seller Academy)**: Led SSR rewrite unifying three codebases into one (0% → 95% shared code, +80% search impressions) across US/ID/VN/TH/MY and launches in Japan and Brazil (~$100K GMV Japan Day 1). Essays come from the Pearl CMS in the `phoenix` monorepo.
  - **US Portal (`seller.tiktok.com`)**: Tech lead for CSR → SSG migration (Rspress then Rsbuild), bringing all Core Web Vitals to "Good" and lifting account-creation conversion by 14.24%; ran a "phantom traffic" forensics investigation that flipped the launch decision.
  - **Seller Assistant & Personalization**: Tech lead for Auto-Translation (14 languages), primary frontend for Mobile V5 multi-agent upgrade across 4 teams, Seller Personalization segments (+10% CTR, +20% PV), and **sa-perf-v2** (seller-perceived chatbot performance in `workbench_components` using Tea, ByteIO, DES, Kani, and Atlas).
  - **Internal Tooling & Workflows**: Contributes to `bytedcli` and `ttadk_cli`; uses Bits, ByteFaaS, ModelArk, Tika, Aime, Mira, Kaboo, and Flux Island. Self-reviews and peer reviews live in `code.byted.org/max.coplan/notes` (written in his own voice: funny and passionate about sellers; business justifications should highlight how work helps AI).
- **Previous Roles**:
  - **Walmart** (2021–2024, Baltimore then Senior SWE in Sunnyvale): Cut `walmart.com` LCP by 500ms and INP by 200ms; contributed Chromium patches and HTTP 103 Early Hints; Tech Lead for Go/SQL release-pipeline tooling; built a React profiling fork, federated GraphQL query-planner debugger, and HAR diff parser.
  - **Clarity Innovations** (2020–2021): Full-stack engineer on an Air Force ops-planning system (Vue/TS PWA, Node/Nest.js, Postgres, k8s CI).
  - **Argonne National Laboratory** (2019): ML engineer researching GANs for cybersecurity threat detection and unbalanced dataset expansion (published).
  - **Leidos** (2018–2019): Software engineer on FAA NextGen air-traffic modernization (Bash/Korn/Python/awk).

## 💻 Machines, OS & Environment
- **Four Primary Environments**:
  1. **Work Mac (`Maxs-MacTok-Pro.local`)**: M3 MacBook Pro, user `bytedance`. Runs Ghostty, tmux, zsh 5.9, atuin, zoxide, Bun, Android Studio, Flux Island, Alcove, and Dayflow. Uses Chrome Dev (not Chrome stable) and Firefox. CorpLink VPN holds port 53 and takes minutes to reconnect after lid close/sleep (check lid/sleep state first on mysterious network timeouts).
  2. **Personal Desktop Workstation**: AMD Ryzen 9 5900X, NVIDIA GeForce RTX 5090, 48 GB RAM. Dual-boots **Debian 13** (GNOME on Wayland; Samsung 980 PRO 1TB SSD; primary boot) and **Windows 11** (Samsung 990 EVO Plus 4TB SSD; gaming & screenpipe).
     - From Debian, Windows is mounted **read-only** at `/mnt/windows` — never remount it read-write; prepare patches on Linux and apply from Windows.
     - From Windows, the Linux disk is accessed via `wsl --mount` and must remain offline in Windows to avoid a `wslservice` deadlock. Never restart `vmcompute` or force-kill `wslservice` without asking first (causes a GPU-PV BSOD).
     - Reached from the Mac via Remote Desktop and OpenSSH (passwordless Microsoft account with `netplwiz` autologon).
  3. **ByteDance Linux Devbox**: Remote `veLinux 2` cloud workstation with passwordless `sudo`, reached over SSH or remote-control bridges. Has no `fd` or `sl`.
  4. **Android Test Phone**: Rooted Google Pixel 4a (LineageOS, Magisk) running the international Lark client, reached via ADB (including over SSH reverse tunnels).
- **Directory Layout**: ~218 repos under `~/code/<host>/<org>/<repo>` (mirrored on devbox) or `~/workspace/github.com/<org>/<repo>`.
- **Editor & Input**: Dvorak keyboard layout. Primary editor is **Neovim** (configured in idiomatic Lua with `vim.pack`, built from source with Zig into `~/.local`), plus Neovide, gVim, and `vscode-neovim`.
- **Home Network**: UniFi router, Teleport VPN, Raspberry Pi Samba NAS, IPv6. Dayflow (macOS) and screenpipe (Windows) record screen/audio all day; recordings and the Bitwarden vault are high-value data that must never be lost.

## 🚀 Active Projects & Open Source
- **Larklish (`vegerot/larklish`)**: Consumer Android Play Store app (not a developer tool) in Kotlin + Jetpack Compose with a Python `larklish-helper`. Intercepts Chinese Lark/Feishu notification previews and translates them to English on-device (ML Kit default; Feishu-hosted Lark translate API option where Latin-heavy input passes through unchanged) while respecting per-group notification settings. Founding rule: workplace chat must never flow through third-party servers.
- **`vegerot/ai-conversations`**: Sapling-backed multi-machine archive of AI coding conversations and Obsidian vault, organized by topic with frontmatter (`date`, `machine`, `agent`, `model`).
- **`vegerot/dotfiles`**: Cross-platform dotfiles symlinked into `$HOME` via `bootstrap.sh` / `bootstrap.ps1`.
- **`coding-model-router`**: From-scratch Go proxy ranking and routing coding LLMs by Artificial Analysis quality vs. cost (serves OpenAI Chat Completions; birthed the `/context-deep` skill).
- **Agent Source Checkouts & Research**: Maintains forks/checkouts of Claude Code (`how-claude-works.md`, sectioned by version — never rebase onto upstream README-ad commits), OpenCode, Codex (nightly source builds across Mac, Debian, and Windows), and Antigravity (`gemini/how-does-antigravity-work.md`).
- **Other Projects & Forks**: Weekly Sunday source builds (`Sapling`, `ripgrep`, `bytedcli`, `OpenCode`, `lark-cli`, `bottom`), `screenpipe` (custom Windows source build under `"screenpipe - Development"` identity), `Dayflow` fork + NAS retention check, `gen1recomp` (Pokémon Yellow LÖVE recompilation + mods), `App Mirror` (macOS Swift window-mirroring input proxy), `APODesktop` (NASA APOD wallpaper app), `Daily Weather` (macOS Open-Meteo notifier), `snek` (Zig + raylib), C/raylib *Game of Life*, `slippi-stats-web`, and `highlight-kindle-book` (always run via its `.venv`).

## 📏 Working Style, Coding & Operational Guardrails
- **Communication & Structure**:
  - Always respond in **English** and write all code, documentation, and Lark messages/docs/forms in English, regardless of Chinese project context.
  - Challenge weak reasoning or flawed assumptions directly when supported by evidence rather than passively agreeing.
  - When discussing Third Reich / Holocaust history, examine causation, contingency, and historiography while keeping antisemitism central.
- **Version Control & Repository Hygiene**:
  - Never run `sl push`, `git push`, `sl pr`, unrequested commits, or branch squashes without explicit permission.
  - Prefer **Sapling (`sl`)** over Git (`ai-conversations` and `dotfiles` are Sapling-backed; Git "detached HEAD" is normal). In Sapling, prefer `sl absorb` over amending, symbolic revsets (`.`, `.^`, `next`) over commit hashes, `--pager=never` to avoid `streampager` PTY hangs, and `sl pull && sl rebase -b. -dmaster` for conflicts (truly understanding both sides).
  - When Git is required, prefer `git restore`, `git switch`, etc. over `git checkout`.
  - On `code.byted.org`, push merge requests via Gerrit-style `git push origin HEAD:refs/for/<target-branch>` with `Change-Id` trailers; the MR title and description must equal the commit title and body (edit the commit, not the web MR).
- **Code & Testing Standards**:
  - Reproduce bugs before fixing them and verify claims empirically on the actual machine ("run it before you reason about it").
  - Use **Test-Driven Development (TDD)**: write unit tests and see them fail (red-green) before implementing the fix/feature. Place Go tests in external black-box `<pkg>_test` packages.
  - Prefer TypeScript `type` aliases over `interface`, and `Readonly<{…}>` when all members are readonly.
  - Prefix boolean identifiers with `is`, `has`, or `will`.
  - Consolidate code comments into fewer, well-explained blocks rather than many tiny comments.
  - Use percentiles rather than means for latency/performance metrics; ignore negligible micro-costs (~30ms).
  - Never recommend open-source projects or browser extensions with fewer than **100 GitHub stars**.
  - Never quote minified code as-is: un-minify it with descriptive names and comments, state that it was un-minified, annotate only function declarations with the original minified identifier, and never put raw minified identifiers (like `Je`, `iO`) into notes or archives.
  - End `progress.md` entries with a `"Next:"` block. When modifying system settings, keep a log so every change is reversible.
- **Shell, Tools & Automation**:
  - On macOS, BSD utilities (`pgrep`, `pkill`, `ps`, `sed`) reject GNU `--long-flags`; use short flags (like `-f`) for those specific BSD tools.
  - On the work Mac, `node` is a per-directory nvm shim.  When experiencing problems with it use `command node` and `command pnpm`, and use `command cp`.
  - Prefer `bun` / `bunx` over `npm` / `npx`, `uv` for Python dependencies, and `jq` for shell JSON parsing (combining fetch + parse in one pipeline).
  - Always send Lark messages via the browser (`lark-browser-send` / Chrome DevTools MCP).
  - Never control `com.openai.codex` directly with generic Computer Use; use `~/ai-conversations/app-mirror` (`com.chatgpt-mirror.proxy`).
  - Ask before killing a running process that Max may be using to reproduce a bug.
  - Prove any manual workflow end-to-end before turning it into a recurring scheduled automation.
