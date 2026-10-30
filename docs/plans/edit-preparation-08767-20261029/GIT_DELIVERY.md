# Scoped Git delivery — 30 October 2026

The user requested checking and pushing the completed Scatter release, website
and related documentation, explicitly excluding ongoing work in other projects.
The destination is the existing `origin` branch `codex/workflow-0.75` at
`MehranCyrus/Cyrus-Scatter`. The preceding committed baseline is
`75c60d54dbfd736ffef135d211863516a63543a7`.

The selected snapshot includes Scatter 0.87.6.7 and its uncommitted preceding
Scatter fixes, the three vegetation preparation implementation files, the help
catalog update, relevant test drivers, delivery/review evidence, maintained
guides and the production website. Independent Arrange, MCP implementation,
Physics Lab, Design/Botany Lab, presentation-studio and unrelated research remain
outside this commit. Shared documentation retains unrelated local draft changes.

A standalone export of the Git index was checked before committing. All **648
native/script/managed source inputs** match the exact qualified snapshot. All
files in the two 0.87.6.7 evidence inventories match their saved SHA-256 values.
Precise `.gitattributes` rules preserve byte-level evidence and source inputs
across checkout, including seven previously unchanged files whose raw line
endings differed from Git's default normalization.

The exported snapshot passes generated-script checks (379 controls and 32
delimiter fixtures), both UI generator suites, all 54 focused Python regressions
and website verification (146 source bindings, five guides, 379 semantic controls,
119 changelog records). Website source bindings in this commit use the actual
committed owner documents. Local bindings for independently edited documents
remain in the working tree. The independent Design Lab navigation addition is
likewise left unstaged.

The selected files contain no compiled installers/modules, Max scenes or
credential material detected by the private-key/token scan. Build outputs,
installers and the website upload ZIP remain local ignored artifacts; their
identities and production/host limits are retained in the release receipts.
Existing native and Max runtime qualification is preserved rather than relabeled
as a new host run. This Git delivery performs no artist installation or website
deployment.
