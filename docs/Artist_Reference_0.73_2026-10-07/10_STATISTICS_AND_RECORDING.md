# 10. Statistics and recording

[Guide contents](README.md)

Find these in **Statistics & diagnostics**. Statistics describe the last completed calculation, which may differ from pending edits in Manual mode.

## Common controls and counts

| Control or term | Meaning |
| --- | --- |
| Read cached statistics | Reads the existing result without requesting new planting. Use this when checking what already happened. |
| Layer / display help | Opens an explanation of settings ownership, order, display budgets and limits. It does not change the scene. |
| Requested / allocated | The amount asked for by the layer or allocated to a set before rejection. |
| Candidates / attempts | Proposed positions considered. Replacements can make this larger than the final result. |
| Accepted / placed | Planting that survived the relevant rules in the last completed result. |
| Rejected / removed | Positions lost to the relevant restrictions or cleanup. The current report is a summary, not a complete explanation for every missing plant. |
| Shortfall | How much of the requested target remains unfilled. It can be a valid outcome when space or attempt limits run out. |
| Protected | Individual artist edits or reservations that the calculation preserves. |
| Conflicts | Retained protected planting that conflicts with spacing. Its survival does not mean the spacing rule is off. |
| Shown | Viewport representation, which may be reduced by display budgets. Point samples and plants are different units. |

## Status words you may see

| Status | Meaning |
| --- | --- |
| Cached / OK | A completed result is available for the current state. |
| Pending update / Stale | Settings changed since the last result. In Manual, use Update now when ready. |
| Not built / -- | No completed planting result is available yet. |
| Empty | A completed result contains no planting. Check sources, population shares and restrictions. |
| Limited | The viewport displays a subset of the result. |
| Hidden | Viewport display is hidden. The enabled layer can still affect spacing and rendering. |
| Off | The setup, layer or required input is disabled. |
| Error | A calculation or input problem needs attention. Read its message; an older visible result may still be present. |

Build time describes calculation work, not the frame rate actually presented while navigating or playing animation.

## Advanced: Local diagnostic recording

Recording is built into Scatter. **You do not need MCP to use it.** It starts off and stays local unless you deliberately share a saved report or permit an assistant to read a recording.

| Control | Meaning |
| --- | --- |
| Start recording | Starts a short record of plugin activity. A new recording replaces the previous recording, so save the previous one first if needed. |
| Stop | Stops recording and keeps the collected history available for saving. |
| Save report... | Choose where to save the report. Saving stops recording and writes the retained history. It does not upload it. |
| Read recording status | Reads recorder state without calculating the scene. The displayed state is read on request rather than continuously refreshed. |
| Recording status / scope information | Shows whether recording is active, its limits and its scope. The recording covers plugin activity in this Max session, potentially including other Scatter setups. |
| Workflow & ownership | Reveals a reminder of the intended workflow and which settings belong to the setup, layer or set. It is an information panel. |

The recorder keeps at most ten minutes, 4,096 events and 4 MiB. It is a bounded troubleshooting history, not a permanent database of every user action. It does not record a full video, reconstruct every click, or automatically become AI training material.

## Report a problem usefully

1. Save a test copy of the scene.
2. Start recording just before the problem.
3. Perform the smallest sequence that shows it: for example, Add layer once or leave Live idle while unrelated animation plays.
4. Stop and save the report.
5. Write what you expected, what actually happened, the selected layer/set, update mode and whether rendering or playback was active.

For an error dialog, keep its exact text. A report should accompany the visible symptom; the current recorder does not replace that description.
