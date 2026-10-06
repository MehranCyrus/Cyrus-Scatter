# Proposed record examples

All JSON files here are **synthetic design examples**, not real scene records, training samples, authorization grants or requests accepted by current Cyrus MCP. Names, values, IDs and budgets illustrate contracts only. No model was trained from them and no candidate was rendered.

| File | Illustrates |
| --- | --- |
| [candidate_pair.json](candidate_pair.json) | Two related recipes with the same context/view profile and distinct parameters |
| [feedback_event.json](feedback_event.json) | Relative preference without inventing absolute acceptance or training consent |
| [batch_scope.json](batch_scope.json) | A draft bounded study scope that is explicitly not authorized |
| [scene_graph.json](scene_graph.json) | World-space relationships with units, provenance and hard/soft semantics |
| [diagnostic_event.json](diagnostic_event.json) | Correlation fields for a hypothetical invalidation event |
| [dataset_manifest.json](dataset_manifest.json) | Eligibility review excludes synthetic/unconsented evidence |

The package validator checks parsing, cross-references and key semantic distinctions. It does not replace future production JSON Schemas, authorization enforcement, host tests or model evaluation.
