# Try Cyrus Automation on this workstation

The MCP package is installed and registered in Codex as **cyrus-scatter**. Its verified build is **1.0.0-d654c4a224df**. The native Cyrus engine remains version **0.64**.

A separate **Cyrus_MCP_Demo.max** test session is left open with 1,200 plants and read-only Automation inspection connected. Image sharing is off. Its private test timers have been stopped. Your original artist scene and the Brush demo remain separate.

## Open the panel

In Max 2027, choose **Scripting → Run Script**, then run:

```text
C:\Users\Mehran\.cyrus-scatter\mcp\1.0.0-d654c4a224df\host\Start_Cyrus_Automation.ms
```

Only one Max session can use this default connection at a time. Close the Automation panel in another Max session before opening it in your own scene. Closing this panel keeps its generated layout in Max. Escape works when the panel has keyboard focus.

Reconnect the `cyrus-scatter` MCP connection in Codex, or start a new conversation, if its seven tools are not yet visible. No additional OpenAI API key is needed by this package.

## First test: inspect your existing scatter

1. Select one existing Cyrus controller in Max.
2. Click **Inspect selected Cyrus scatter (read-only)**. Enable image sharing only if you want a viewport image sent to your assistant.
3. Ask Codex:

> Use the Cyrus Scatter MCP tools to inspect my connected scatter. Report its layers, requested/generated/displayed counts, cached errors, retained Mesh/Point Cloud statistics and loaded plugin identity. Explain which numbers are cached and what they cannot tell us. Do not modify the scene.

This workflow reads existing layouts with up to 32 layers. It never grants permission to edit them or rebuild Manual previews.

## Second test: create a small procedural layout

Use a separate simple scene with a flat convex plane, one or two small static source meshes, and a closed straight convex spline inside the plane. Select and assign them using the panel's site, assets and planting-spline buttons. Click **Connect selected scope**.

> Read the connected Cyrus scope and propose two planting layers with 600 total plants using the enrolled assets and regions. Use deterministic seeds, scale 0.8–1.2 and random yaw. Validate and describe the proposal. Wait for my approval in Max before applying. After application, report actual counts and capture the viewport if sharing is enabled. Do not refine automatically.

Review the actual assets, regions and counts in Max, then click **Approve displayed proposal** and tell Codex to continue. You can approve one further refinement. **Undo last result / reject refinement** restores the previous result if no unrelated Undo action has intervened. **Disconnect scope and continue manually** leaves ordinary editable Cyrus layers and derived masks.

## Limits relevant to this test

Design enrollment currently supports horizontal convex sites, static baked meshes or supported simple primitives, at most three layers, 2,000 requested plants, and 10,000 aggregate input triangles. Complex terrain, renderer proxy inputs, Brush automation and ML are separate roadmap work. The first test above can still inspect cached data from heavier existing scatters.

The full [user guide](../../CyrusMCP/README.md) covers geometry, recovery and installation. The [report](REPORT.md) records tests and limitations; [roadmap status](ROADMAP_STATUS.md) explains what comes later. The distributable folder is `dist/Cyrus-MCP-1.0.0-Max2027-Release`; Python 3.11 x64 and Cyrus in Max 2027 are prerequisites on another workstation.
