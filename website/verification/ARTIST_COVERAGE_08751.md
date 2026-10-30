# Artist-facing website coverage — 27 October 2026

Scope: important delivered features and practical workflows through 0.87.5.1,
rather than an entry for every historical patch. No plugin or interaction source
was changed. The concurrent 0.87.5.2 development work is not a public delivery.

## Coverage reviewed

| Artist need | Current public destination |
| --- | --- |
| Ordered layers, surfaces, sources and containers | Artist guide: Start with a layer; Surfaces, models and optional containers |
| Count, density, grids and source assignment | Artist guide: Layout and Amount; Layout & soft boundaries |
| Maps, mesh channels, slope and altitude | Artist guide: Image, map and surface density; Slope and altitude filters |
| Paint, erase, fades and spline exchange | Artist guide: Vector painting; Paint and spline snapshots |
| Masks, transforms, model clearance and Relax | Artist guide: Area limits, transforms and spacing |
| Instance edits, copy variation and binding limits | Artist guide: Edit instances; Copy and import variation |
| Preview budgets, materials, output and diagnostics | Artist guide: Preview, updates, output and diagnostics |
| Shared source geometry, compact poses and CPU output | Preview chapter and Features: Preview, updates & output |
| Mesh/Textured mesh Wireframe | Preview chapter and Features |
| Collider/React roles and automatic contact updates | Artist guide: Plants that respond to nearby objects |
| Independent bending gap, hide margin and hide area | Plant response chapter; whole-rooted-group meaning and fixed-root limits explained |
| Source preparation, selected/isolated leaves and fixed bases | New Source Preparation Editor chapter and Features story |
| Piece roles, guide correction, private sphere and navigation | Source Preparation Editor chapter |
| Trunk/custom colliders and proxy limits | Artist guide: Lightweight tree colliders |
| Individual model library, shared files and collections | Plant library page; Shared models, recipes and textures |
| Scene/Portable/Settings save choices and authored state | Complete planting recipes; Features: Scene presets & portable recipes |
| Merge, asset collection, transfer and dependencies | Complete planting recipes; Download requirements |
| Settings/curve presets and Surface Analyzer | Named settings and curve presets; independent Analyzer guide |
| Manual/Live, retained results and practical troubleshooting | Workflow, artist guide and Troubleshooting |
| Current install method and actual supported package | Landing release panel and Download: 0.87.5.1 Max 2027 MZP |
| Optional MCP, learning and future work | Separate bounded MCP guide and Current/Experimental/Planned roadmap |

Six meaningful recent milestones were added to the existing changelog: the
preparation editor, nearby-contact work reuse, selected-leaf preparation,
independent hiding/Wireframe, authored portable recipes and compact shared
display. Earlier patch-level history is retained without inventing missing
dates or implying that every internal revision needs a marketing entry.

## Gaps corrected in this follow-up

The initial update missed the landing EXE wording, an Analyzer-bundling statement
and a duplicate old product-status paragraph. These are corrected. The preparation
editor now has a complete public workflow rather than only a button mention.
Wireframe, shared display and hiding semantics have explicit explanations.

The release label now follows `release.json` instead of the moving development
catalog. This prevents concurrent development from relabeling an older installer.
Controls remain checked against the existing semantic catalog; the verification
receipt records its separate development version (0.87.5.2 at this check).

## Executed checks and artifact

Content synchronization, source/control/link verification, TypeScript/Vite build,
archive CRC and every packaged file hash pass. Five guide documents, 364 semantic
controls, 37 capability records, 54 generated guide links and 45 static navigation
destinations are checked. A 12-page local browser review covered Home, Download,
Features, Library, artist guide, Analyzer guide, Roadmap, Changelog, Controls,
Workflow, Troubleshooting and About. Each rendered, no console errors were
reported, and checked stale current-release phrases were absent. The new feature
link reached the Source Preparation Editor chapter, which was visually inspected.
This is not a new mobile/responsive, full-interaction or plugin qualification.

Latest upload:
`dist/website/cpanel-2026-10-27-hOb2ZwMh/CyrusScatter-website-0.87.5.1.zip`

90 files, approximately 20.91 MiB; SHA-256
`881f4382890e9b06ab422ef6c7c0296ef0b0ba2009df0edb8bfdaf51064c71a3`.

This supersedes the earlier CaZ4JDu5 upload for website content. The included
0.87.5.1 MZP is unchanged and retains its original qualified identity. Sources
and upload are local; the live site has not been deployed and no Git push occurred.
