from pathlib import Path
import subprocess,json,hashlib
root=Path.cwd();out=root/'build/edit-size-review-20261029-01/final-checks';out.mkdir(exist_ok=False)
commands={
 'python':['build/mcp-venv/Scripts/python.exe','-m','pytest','tools/tests/test_build_inputs.py','tools/tests/test_build_only_receipt.py','tools/tests/test_package_version.py','tools/tests/test_recipe_contract.py','CyrusMCP/tests/test_feature_catalog.py','-q'],
 'ui':['node','--test','AminScatter/tools/ui/approved-layout.test.cjs','AminScatter/tools/ui/assemble-template.test.cjs']}
receipt={}
for name,command in commands.items():
 result=subprocess.run(command,cwd=root,capture_output=True,text=True,encoding='utf-8',errors='replace')
 log=out/(name+'.log');log.write_text(result.stdout+result.stderr,encoding='utf-8')
 receipt[name]={'command':command,'exit_code':result.returncode,'log_sha256':hashlib.sha256(log.read_bytes()).hexdigest(),'explicit_test_sources':{p:hashlib.sha256((root/p).read_bytes()).hexdigest() for p in command if p.endswith(('.py','.cjs'))}}
 print(name,result.returncode,result.stdout[-500:])
 (out/'receipt.json').write_text(json.dumps(receipt,indent=2))
 if result.returncode:raise SystemExit(result.returncode)
