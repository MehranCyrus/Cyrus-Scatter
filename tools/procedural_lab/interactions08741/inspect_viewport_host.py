"""Read display settings and cached counters from an owned terrace scene."""
from pathlib import Path
import json
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
try:
    root = r.TRoot
    fields = ('viewportMode', 'viewportInstances', 'viewportFaces',
              'viewportNavigationInstances', 'viewportNavigationFaces',
              'viewportNavigationPoints', 'pointsPerPlant', 'showPoints', 'autoRender')
    owner = r.CyrusPointOwner(r.TOwner)
    plan = list(r.cyrusRetainedViewportStats(owner)) if r.isValidNode(owner) else []
    report = {'status': 'complete', 'settings': {f: str(getattr(root, f)) for f in fields},
              'viewport_plan': [int(x) for x in plan],
              'viewport_plan_fields': ['version','idle_points','navigation_points','idle_proxies','navigation_proxies',
                                       'idle_mesh_triangles','navigation_mesh_triangles','idle_box_instances','navigation_box_instances',
                                       'memory_reduced','cumulative_idle_draw_calls','cumulative_navigation_draw_calls'],
              'layers': [{'name': str(root.layerNames[i]), 'foliage_fraction': float(leaf.interactionFoliage),
                          'cached_points': int(leaf.cachedPointCount), 'placements': int(leaf.generatedCount)}
                         for i, leaf in enumerate(root.layerObjects)],
              'scope': 'Read-only snapshot of the current private host fixture; limits and actual displayed counts differ.'}
except Exception:
    report = {'status': 'failed', 'error': traceback.format_exc()}
(host / 'viewport-settings.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
