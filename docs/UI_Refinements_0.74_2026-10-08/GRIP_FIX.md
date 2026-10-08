# 0.74 list resize correction

8 October 2026. Supersedes the original 0.74 installer for list resizing. Version remains **0.74.0**; identify this correction by its dated delivery folder and package hashes.

## Failure and correction

The artist reported `Unknown property: "pos" in dotNetClass:System.Windows.Forms.Cursor` from receiving-surface, layer, model/container and brush-history handles. The same expression was reproduced in an isolated Max 2027 host: MAXScript resolves `.Position` through its `pos` alias, which is not the .NET Cursor property. Every generated handle used that expression.

The shared UI generator now converts the mouse event's local point to screen coordinates with `PointToScreen`. This keeps a stable drag reference when the grip or rollout moves during layout. There is no global Cursor position access. Resizing changes only list height and presentation state; the list items, selection and scatter placement model remain intact.

Mouse movement previously passed through a generic event wrapper that called layout even without an active drag. Grip events now use their own lifecycle: left-button start, layout only when height changes, release, capture loss, rebind and close. The height bounds remain 42–900 requested pixels; native list row sizing can round the displayed height. Mouse hover and right clicks do not resize.

Raised white bars have been replaced with flat dark eight-pixel strips, two short centered grip lines and the vertical-resize cursor. Handles do not take keyboard tab stops. All native and popup list controls use the same implementation.

## Verification

[The focused regression](../../tools/procedural_lab/Max_UI_074_Grips.ms) raises actual WinForms events through reflection in an owned Max profile. It covers **27 mounted controls**: all 10 main-panel list types, the same 10 through source-container editing, and all 7 list controls in the floating editor. Conditionally hidden lists are explicitly enabled in the fixture to exercise their handlers too.

Checks passed for down/move/up, a stationary screen point after reflow, minimum/maximum size, idle movement, right click, capture loss, rebind, paint callbacks, unchanged contents/selection and no placement rebuild. Closing the main panel and popup during a drag also passed. An event-resized height survived reselection while pending Manual edits remained unpublished. Both existing `UI074Run` and `UI074Views` regressions passed on the corrected script.

Generator/catalog consistency and the added event-wrapper regression passed. The native modules are byte-identical to the previously tested 0.74 modules; all native build inputs still match the successful build receipt. This is a MAXScript/generator correction, not a new native build. [Exact identities and receipts](GRIP_EVIDENCE.json).

Physical pointer input and screenshot/DPI inspection remain unverified: the computer-use runtime again failed before window access with `failed to write kernel assets: The system cannot find the path specified`. Event dispatch and paint execution establish behavior, not visual acceptance across DPI settings. The previous package's programmatic height checks did not exercise mouse handlers and missed this defect; the new regression specifically closes that gap.

## Corrected installer

[Cyrus Scatter 0.74.0 for Max 2027](../../dist/UI_Grip_Fix_0.74_2026-10-08/Max2027/CyrusScatter-0.74.0-Max2027.mzp) · [package identity](GRIP_PACKAGE.json).

Save your work, run this MZP through **Scripting > Run Script**, then **restart Max**. Use this folder instead of the first 0.74 installer. Analyzer and MCP do not need an update. Normal installed files and artist scenes were not changed by this investigation.
