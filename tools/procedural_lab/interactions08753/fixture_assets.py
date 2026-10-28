"""Resolve assets only inside the campaign's disposable copied scene.

The artist input and its materials are never saved or modified on disk. Keep
retained capture suspended until the copied scene has its supported color mode
and unambiguous source-model bitmap paths.
"""
from pathlib import Path


def prepare_owned_fixture(runtime, repository, report, scatter_root=None):
    previous = bool(runtime.CyrusPointSuspended)
    previous_busy = bool(runtime.CyrusPointBusy)
    runtime.CyrusPointSuspended = True
    runtime.CyrusPointBusy = True
    try:
        report['input_color_pipeline'] = str(runtime.ColorPipelineMgr.Mode)
        requested = runtime.GardenSupportedOCIO
        if requested == runtime.undefined or bool(requested):
            runtime.ColorPipelineMgr.Mode = runtime.Name('OCIO_Default')
        report['test_color_pipeline'] = str(runtime.ColorPipelineMgr.Mode)
        if scatter_root is None:
            owner = next(node for node in runtime.objects
                         if str(runtime.classOf(node.baseObject)) == 'AminScatterObject'
                         and node.baseObject.overlapOwner == runtime.undefined)
            scatter_root = owner.baseObject
        roots = [Path(repository) / 'Test Scene/Organized Models/Plants/Outdoor/Outdoor_Plants_01',
                 Path(repository) / 'Test Scene/Rock_Boulder_10']
        relinks, unresolved = [], []
        report['owned_asset_relinks'] = relinks
        report['owned_asset_unresolved'] = unresolved
        for leaf in scatter_root.layerObjects:
            for node in leaf.validSources():
                if not runtime.isValidNode(node) or node.material == runtime.undefined:
                    continue
                for bitmap in runtime.getClassInstances(runtime.Bitmaptexture, target=node.material):
                    raw = Path(str(bitmap.filename))
                    if raw.is_absolute() and raw.is_file():
                        continue
                    candidates = [base / raw for base in roots if (base / raw).is_file()]
                    if not candidates and raw.name:
                        candidates = [path for base in roots for path in base.rglob(raw.name)
                                      if path.is_file()]
                    unique = list(dict.fromkeys(candidates))
                    if len(unique) == 1:
                        bitmap.filename = str(unique[0])
                        relinks.append({'source': str(node.name), 'map': str(bitmap.name),
                                        'from': str(raw), 'to': str(unique[0])})
                    else:
                        unresolved.append({'source': str(node.name), 'map': str(bitmap.name),
                                           'path': str(raw),
                                           'candidates': [str(path) for path in unique]})
        if unresolved:
            raise RuntimeError('Owned fixture has unresolved or ambiguous bitmap assets; '
                               'see owned_asset_unresolved before qualifying material display')
    finally:
        runtime.CyrusPointBusy = previous_busy
        runtime.CyrusPointSuspended = previous


def load_owned_fixture(runtime, scene, repository, report):
    previous = bool(runtime.CyrusPointSuspended)
    previous_busy = bool(runtime.CyrusPointBusy)
    runtime.CyrusPointSuspended = True
    # filePostOpen deliberately clears CyrusPointSuspended. Keep the existing
    # sync reentrancy guard held across load as well, so that callback cannot
    # capture relative maps before this owned fixture resolves them.
    runtime.CyrusPointBusy = True
    try:
        if not runtime.loadMaxFile(str(scene), quiet=True, useFileUnits=True,
                                   missingDLLsAction=runtime.Name('logmsg')):
            raise RuntimeError('Could not load the owned copied fixture: ' + str(scene))
        prepare_owned_fixture(runtime, repository, report)
    finally:
        runtime.CyrusPointBusy = previous_busy
        runtime.CyrusPointSuspended = previous
