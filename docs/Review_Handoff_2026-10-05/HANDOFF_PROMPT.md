# Prompt for a new independent review conversation

Copy the text below into a new Codex conversation opened in `F:\Cursor\_Cyrus_Apps\CyrusScatter`.

---

I want an independent second-opinion engineering review of Cyrus Scatter before we continue coding. Review my requirements against the actual current local implementation, code quality, architecture, correctness, performance and test evidence. Do not assume the previous agent's reports prove correctness.

Start here:

`F:\Cursor\_Cyrus_Apps\CyrusScatter\docs\Review_Handoff_2026-10-05\README.md`

Read CURRENT_STATE.md, REQUIREMENTS_REVIEW_MATRIX.md and REVIEW_PLAN.md in that folder, then the linked procedural design, implementation and runtime evidence. Inspect the source itself and both tracked and untracked changes. The committed baseline is `53bfc5d1c76929958dbeb29f5d4c746b2321d0ac`; the branch at handoff was `codex/planting-groups`. Substantial 0.7 work is local and is not yet committed. Preserve unrelated licensing work and all artist scenes/profiles.

My intended system is procedural: layers and paint sets evaluate in explicit top-to-bottom order, reuse caches, and keep stable identities. We need independent collision rules within a paint set, between paint sets, and between layers; adjustable source/instance radii; editable Brush coverage on flat and curved static surfaces; and separate options for excluding painted coverage, filling between plants, and bounded replacement of rejected candidates. Each layer owns its settings; global controls remain separate. Paint sets share declared layer defaults and population. Artist edits, include/exclude areas, Manual/Live, Undo, persistence and statistics must agree with the calculation model.

Preserve our measured retained Mesh/Point Cloud improvements from 0.64/0.63. Navigation and UI browsing should not regenerate placements or re-upload unchanged buffers. Do not promise unlimited FPS or equate synchronous redraw timing with presented FPS. Assess CPU work, cache dependencies, memory, worst-case bounds and host-thread safety before recommending GPU compute or more abstraction.

Pay special attention to the latest **unfinished** UI work: native command-panel columns when the sidebar is widened, reliable expansion/scrolling, and automatic saving of spacing fields without Apply spacing. An intermediate test passed event/lifecycle checks but still showed unused layer pages and unexpected page order. The final native helper was changed after that test; it only has a Max 2027 build/native-test pass, not final Max UI validation. The current script/native pair differs from the existing MZPs. Verify source/binary identities before testing; do not mix the new script with an older loaded DLL.

Also review the MCP boundary: policy 3 is currently read-only, while existing closed plan schemas retain their own supported behavior. ML is future work, not an implemented model. Check those claims and whether the extension boundaries are sensible without inventing missing capabilities.

Please:

1. Establish the exact worktree/diff/untracked scope and source fingerprints.
2. Trace generation → eligibility/Brush → transforms/Edit/radius → three collision scopes → cleanup/refill → atomic publication → preview/exact output/export, including invalidation and failure paths.
3. Compare every requirement in the handoff matrix with actual code and tests. Challenge incorrect assumptions and unnecessary complexity; preserve working behavior rather than rewriting for style.
4. Run relevant offline tests and, where useful, isolated Max 2027 tests on disposable scenes. You may use computer tools for those private tests. Do not disturb my artist scene or install into my normal Max profile. Follow available tool/skill instructions.
5. Use official SDK documentation or primary sources when an API contract is uncertain. Distinguish source facts, reproduced results and hypotheses. Review test quality and missing scenarios, not only pass counts.
6. Report findings by severity with exact file/line, impact, reproduction/evidence and the smallest reasonable fix. Include what is solid, what is partial/missing/unverified, any requirement tradeoffs, and a prioritized next implementation loop with acceptance criteria.

Produce a new dated Markdown review folder and a concise summary for me. Review and report first; do not implement production fixes, package/install, commit, push or perform broad cleanup in this review. Temporary diagnostic fixtures are fine in the existing ignored test workspace. Stop after the review so we can decide the next coding loop from the findings. Version 0.7 is our development label; 1.0 is reserved for publication readiness.
