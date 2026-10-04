# Synthetic contract illustrations

These files are hand-authored examples, not model outputs, training samples, measurements or live-scene plans.

| File | Status and purpose |
| --- | --- |
| [artist-style-profile.json](artist-style-profile.json) | Proposed portable profile; references and learned components are illustrative or absent |
| [design-recipe.json](design-recipe.json) | Proposed intermediate recipe, including an explicit unsupported-preference notice and placeholder role/zone bindings |
| [compiled-plan-v2.json](compiled-plan-v2.json) | Current executable plan **shape** with synthetic IDs; checked against existing Pydantic and independent host-side shape/settings validators |

There is no profile/recipe schema implementation or compiler in this delivery. The plan was constructed by hand to demonstrate the mapping. Passing shape validation does not establish enrollment, asset suitability, spatial feasibility, artist approval, actual count or visual quality. It must not be submitted unchanged to a live scene.

The example starts from a profile that likes spatial clumps. The pilot recipe explicitly says that preference is not expressed and would require acceptance of a simplified draft. This is intentional: current MCP supports random weighted sources and counts but does not expose a positional-clump primitive. The future compiler must make that distinction visible.

The two layer budgets total **640 candidates**, sampled under the existing site's count/mask semantics. They are not a promise of 640 final plants. `region_demo_garden`, `source_demo_tree`, `source_demo_shrub` and `context_demo` do not name real enrolled objects.

Recipe layer order maps to plan pair indices: canopy is index 0; shrubs index 1. Role weights, scale ranges, source radii and gaps are illustrative values in the stated units. They are not horticultural recommendations. The plan preserves `underfill: allow`, explicit Manual mode and bounded Proxy display.

The verification script also confirms that inserting an unsupported `style_profile` field into the plan is rejected by both existing validation layers. This checks a real architectural boundary; it does not test a future compiler or ML model.
