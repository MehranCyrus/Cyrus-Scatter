# Start the next Cyrus Scatter conversation here

7 October 2026. Workspace: `F:\Cursor\_Cyrus_Apps\CyrusScatter`. This handoff follows a source/docs review, new offline checks and the combined website task. It is not a new plugin release or full Max qualification.

## Read in order

First read the root [AGENTS.md](../../AGENTS.md) and its [workflow guide](../AGENT_WORKFLOW.md). They define working practices; this dated handoff supplies the baseline and outstanding work.

1. [Current status and identities](README.md).
2. [Code findings](CODE_REVIEW.md) and [documentation reconciliation](DOCS_RECONCILIATION.md).
3. [Next loops and acceptance](ROADMAP.md).
4. `docs/Layer_Actions_Fix_0.73_2026-10-07/README.md`, then the compact-layout and full-qualification reports with their separate identities.
5. `docs/Artist_Reference_0.73_2026-10-07/README.md` for current artist language and `website/README.md` for the visual website.

## Baseline and preservation

- Branch at this review: `codex/unified-0.73`; committed baseline `d55dfa88cbeda7af366e4510ac3119a749368958`.
- Product 0.73.0, script caption 0.73, serialization 54, model `CyrusUnified1`; Analyzer remains independently versioned at 0.14.
- Latest generated script SHA-256: `9614f6b7d95c0e7c97f9bbe7fa2cb5a770f7a3eca813f7a9f55ea68463d114bf`; loaded payload fingerprint expected `562300e09f3be559388b05899823d5455e6e7562ce571ae5633a1d093cfc74c7`.
- Latest corrected MZP: `dist/Layer_Actions_Fix_0.73_2026-10-07/Max2027/CyrusScatter-0.73.0-Max2027.mzp`, SHA-256 `92d1f93600c89e02133d90a9a4f6072db1daae2f0e7a0c110aa60f3de28ba9a7`.
- The inspected **installed script on disk is older**, SHA-256 `53bf85f9a2cfe1034468919c408d4c73ca6e865f7e1b9c816cc7375fe12f10fa`, at `C:\Users\Mehran\AppData\Local\Autodesk\3dsMax\2027 - 64bit\ENU\scripts\CyrusScatter\CyrusScatter.ms`. Do not infer loaded module identity from this file or the version caption.
- Review/docs/website work is local and uncommitted. Always inspect tracked changes **and untracked files**. `Landing Page Design/`, the artist-reference ZIP, and `website/` were already untracked when this round started. No push or commit was performed by this round.
- Preserve all artist scenes/models/maps, the normal Max profile, licensing source, and existing reference designs. Only use owned disposable profiles/scenes for new runtime tests. Check process identity before stopping a helper; never terminate Max by executable name alone.

## What this round established

Fresh checks: 141 Python MCP/tools tests, 14 freshly built Scatter core suites, one freshly built Analyzer core suite, generator/control integration (240 controls, 22 fixture delimiter checks), approved-layout structural checks. All passed. Eight latest source identities, 33 evidence entries and the package matched. These checks did not launch Max, compile an SDK plugin, create an installer, render, or measure FPS/VRAM.

The two independent audit agents reviewed source and current documentation. They retained the historical cold Undo gate and identified a separate source-level Manual/unrelated-Undo path requiring reproduction. They also confirmed existing Brush derived-memory and Proxy draw limits and the limited MCP/experimental-ranker/licensing boundaries. Do not convert this bounded review into an assertion that every handler or algorithm is proven.

The combined website builds on the earlier local guide and selected ideas from the supplied designs. It is educational and local. Read its latest verification report to distinguish final combined checks from the preserved first-edition evidence. The original artist Markdown remains unchanged; current navigation docs were corrected around it. The capability matrix is hash-pinned into production catalog data and was intentionally left unchanged.

## Recommended first coding loop

Verify the corrected loaded script/native pair in an isolated Max 2027 profile. Then isolate first cold container Undo history loss and separately test pending Manual edits across unrelated scene Undo/Redo. Retain a failing witness before fixing. Use the smallest causal fix and verify relevant layer/Brush/Edit/container Undo, failed successor retention, save/reopen and idle/cache identities.

Do not redesign the UI or add AI features during this first loop. The compact layout is the agreed baseline. Later loops are in ROADMAP.md. Package and normal-profile installation are separate delivery steps; do not silently overwrite the user's profile to make a test pass.

## Copyable prompt

> Continue Cyrus Scatter in `F:\Cursor\_Cyrus_Apps\CyrusScatter`. First read `docs\Status_0.73_And_Website_2026-10-07\HANDOFF.md`, its status, code review, reconciliation and roadmap, then inspect the actual worktree including untracked files. Treat compact 0.73 plus the latest Layer Actions correction as the source baseline. Verify exact current/package/loaded identities: the prior review found the normal-profile installed script still matched the earlier compact package. Start with the recommended isolated Max 2027 Undo/Manual qualification loop, preserving artist scenes, the normal profile and existing retained display/Brush/identity behavior. Distinguish historical runtime evidence, new reproduced results and static hypotheses. Do not expand to feature work until the first loop's acceptance is understood. Keep the documentation and visual guide aligned with any proven behavior change, and report evidence and remaining gates. No commit, push, public deployment or normal-profile installation is authorized by this handoff alone.
