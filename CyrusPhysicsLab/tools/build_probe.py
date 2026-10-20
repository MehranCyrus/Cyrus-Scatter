"""Build the private Max 2027 SDK Painter driver, never part of the product."""
from pathlib import Path
import argparse
import subprocess
from build import ROOT, compiler_environment

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument("--output",type=Path,required=True)
args=parser.parse_args()
folder=args.output.resolve()
if not folder.is_relative_to(ROOT/"build"):
    parser.error("Private probe belongs under ignored build/")
sdk = ROOT / "build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk"
environment = compiler_environment()
for command in (
    ["cmake", "-S", str(ROOT / "CyrusPhysicsLab/tests/paint_probe"), "-B", str(folder),
     "-G", "Ninja", "-DCMAKE_BUILD_TYPE=Release", "-DCYRUS_MAX_YEAR=2027", f"-DMAXSDK_ROOT={sdk}"],
    ["cmake", "--build", str(folder)],
):
    subprocess.run(command, env=environment, check=True)
