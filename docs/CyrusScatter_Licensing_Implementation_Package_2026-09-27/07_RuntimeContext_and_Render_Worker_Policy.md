# 07 — RuntimeContext and Render-Worker Policy

## Why this is the hardest policy area

Cyrus Scatter's final render is orchestrated through MAXScript/PFlow, and render farms can launch either `3dsmaxcmd.exe` or `3dsmax.exe`. A MAXScript boolean is therefore not a secure definition of “render worker.”

## RuntimeContext

```cpp
struct RuntimeContext {
    HostExecutable host;        // 3dsmax, 3dsmaxcmd, unknown
    HostMode mode;              // interactive, render, networkRender, unknown
    bool uiAvailable;
    bool sceneLoaded;
    bool renderInProgress;
    bool trustedRenderWorker;
    uint32_t maxYear;
    std::string renderer;
};
```

## Detection hierarchy

1. native process/executable identity;
2. native Max SDK render/network state where reliable;
3. command-line/environment evidence captured natively;
4. render lifecycle evidence;
5. script signal only as supporting context, never sole authority.

## Conservative policy

- `3dsmaxcmd.exe` rendering an existing scene is the easiest trusted render-worker case.
- Interactive `3dsmax.exe` should require an authoring license.
- Farm-launched `3dsmax.exe` needs a validated native detection strategy before free render policy is enabled.
- If context is ambiguous, do not silently grant authoring. Either require a seat or enter a narrowly-scoped render path after an explicit tested signal.

## Render scope

A render worker may:
- evaluate saved Scatter parameters;
- run placement math;
- apply saved CS Edit state;
- create transient PFlow required to render;
- perform Analyzer recomputation only if proven necessary for faithful saved-scene rendering.

It may not:
- create/edit Scatter interactively;
- mutate CS Edit;
- bake/export;
- use license UI;
- consume an authoring floating seat.

## Runtime experiment required

Test Deadline 3ds Command and normal 3ds Max workers separately. Deadline documentation confirms it can use `3dsmaxcmd.exe` or a 3ds Max application plugin, so process name alone does not cover all farm workflows.
