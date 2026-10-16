"""Run serial fixtures against one explicitly owned grid qualification host."""
from pathlib import Path
import argparse,subprocess,sys
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);p.add_argument('fixtures',nargs='+');a=p.parse_args()
folder=a.profile.resolve();assert folder.parent==ROOT/'build/mcp-qualification' and folder.name.startswith('foundation-roadmap-grid0850-')
for name in a.fixtures:
 script=(ROOT/'tools/grid_0850'/name).resolve();assert script.parent==ROOT/'tools/grid_0850' and script.is_file()
 subprocess.run([sys.executable,str(ROOT/'tools/eleven_phases/request.py'),str(folder),str(script),'--timeout','180'],cwd=ROOT,check=True)
