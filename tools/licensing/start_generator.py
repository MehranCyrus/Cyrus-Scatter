"""Start the owner GUI in a private, pinned Python environment."""
from pathlib import Path
import argparse,os,subprocess,sys,venv

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');args=parser.parse_args()
    here=Path(__file__).resolve().parent
    # Outside LocalAppData virtualization used by packaged launchers. The same
    # owner key must be visible from Codex, a terminal and Explorer.
    store=Path(os.environ['USERPROFILE'])/'.CyrusScatter/LicenseIssuer'
    if not (store/'issuer.dpapi').is_file():
        raise SystemExit('Owner key is missing. Follow tools/licensing/README.md; do not replace an existing authority.')
    runtime=store/'runtime';python=runtime/'Scripts/python.exe'
    if not python.exists():venv.EnvBuilder(with_pip=True).create(runtime)
    check=subprocess.run([str(python),'-c','import cryptography;assert cryptography.__version__=="50.0.2"'],capture_output=True)
    if check.returncode:
        subprocess.run([str(python),'-m','pip','install','--disable-pip-version-check','-r',str(here/'requirements.txt')],check=True)
    subprocess.run([str(python),'-c','import tkinter; import cryptography'],check=True)
    if args.check:
        print('Owner key present; generator dependencies ready.');return
    subprocess.run([str(python),str(here/'issuer.py'),'gui'],check=True)

if __name__=='__main__':main()
