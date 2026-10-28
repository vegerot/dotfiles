---
name: smash-codebase
description: See the local Super Smash Bros. checkouts under ~/code (Melee decomp, Slippi, Brawlback, Project+, Dolphin). Use whenever asking implementation, introspection, or behavior questions about Smash, Melee, Slippi, .slp replays, Brawl, Brawlback, Project+, or Dolphin netplay.
---

When investigating Super Smash Bros. Melee, Slippi, Brawl, Brawlback, Project+, or the Dolphin builds those projects use, read the local checkout.

The clones are scattered under `~/code`. Refresh the inventory with `findrepo melee`, `findrepo slippi`, `findrepo brawl`, `findrepo smash`, and `findrepo dolphin`.

Project Slippi lives under `~/code/github.com/project-slippi/`:

- `project-slippi` — mission statement and map of the Slippi ecosystem (recording, playback, replays, launcher).
- `slippi-launcher` — Electron app: Dolphin updates, netplay, replay launch, and analysis.
- `slippi-ssbm-asm` — Melee ASM/Gecko codes for recording, playback, netplay, and console.
- `slippi-wiki` — specs for the `.slp` replay format, Dolphin comm files, and the spectator protocol.

Other Slippi checkouts:

- `~/code/github.com/hohav/py-slippi` — Python `.slp` parser. Its README marks it unmaintained. The successor named there, peppi-py, has no checkout here.
- `~/code/github.com/vegerot/quick-start-slippi` — local Windows GameCube-adapter monitor that focuses or launches Slippi Dolphin.
- `~/code/gitlab.com/Coukaratcha/slippi-stats-web` — web app that charts stats from `.slp` replays.
- `~/code/github.com/geoffreylao/chart-slp-uploader-companion-app` — uploads `.slp` files to chart.slp.

Melee decomp:

- `~/code/github.com/doldecomp/melee` — matching decompilation of Super Smash Bros. Melee (US 1.02, `GALE01`). The README is `.github/README.md`. Contributor docs are in `docs/`.

Brawl:

- `~/code/github.com/doldecomp/brawl` — work-in-progress decompilation of Super Smash Bros. Brawl (USA Rev 2, `RSBE01_02`). The repo has no game assets.
- `~/code/github.com/Brawlback-Team/brawlback-asm` — Syringe/ASM plugin for online and offline Brawlback (rollback for Brawl and Project+).
- `~/code/github.com/Brawlback-Team/brawlback-wiki` — Brawlback docs: getting started, rollback, replays, Ghidra.
- `~/code/github.com/sarahkittyy/brawlonline.net` — Brawl Online: Project+ rollback, Dolphin, game plugin, launcher, and servers. Started as a fork of Brawlback.

Dolphin:

- `~/code/github.com/dolphin-emu/dolphin` — upstream GameCube and Wii emulator. `origin` is `dolphin-emu/dolphin` and the working branch is `master`. This clone also has remotes `brawlback-dolphin` (`Brawlback-Team/Project-Plus-Dolphin`), `project-plus-dolphin` (`Project-Plus-Development-Team/Project-Plus-Dolphin`), and `ishiiruka` (`project-slippi/Ishiiruka`). The `ishiiruka` remote tracks only `slippi`, as `ishiiruka/slippi`; that branch is Slippi's Dolphin fork (Faster Melee lineage) and records and plays back `.slp` files.

When running this skill, fetch/rebase any repos you dive deep into.
