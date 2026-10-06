"""Check settled native Qt page metadata through a private Max fixture API."""
import argparse
from pathlib import Path

from runtime_driver import ROOT,run_script


def qualify(folder):
    inspector=(ROOT/'tools/procedural_lab/inspect_ui_072.py').as_posix()
    code=r'''
        if CSIdleRemove!=undefined do CSIdleRemove()
        CyrusCloseLayerEditor()
        P07New count:32
        select P07Node;max modify mode;modPanel.setCurrentObject P07Root
        if not P07Root.mainUI.controlsReady do P07Root.mainUI.mountTimer.tick()
        for r in P07Root.mainUI.editors do r.open=true
        P07Root.mainUI.bindEditors()
        windows.processPostedMessages()
        if (python.ExecuteFile @"__INSPECTOR__")!=#success do throw "Selected native page inspection failed"
        for leaf in (P07Root.logicalLayers()) do P07Root.removeLogicalLayer leaf
        windows.processPostedMessages()
        if (python.ExecuteFile @"__INSPECTOR__")!=#success do throw "Empty native page inspection failed"
        resetMaxFile #noPrompt
    '''.replace('__INSPECTOR__',inspector)
    result=run_script(folder,code,timeout=120)
    print(result.strip())
    if not result.startswith('SUCCESS '):raise RuntimeError(result)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('folder',type=Path)
    folder=parser.parse_args().folder.resolve()
    if folder.parent!=ROOT/'build/mcp-qualification':raise ValueError('Private Max fixture required')
    qualify(folder)
