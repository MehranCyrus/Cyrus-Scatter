"""Reuse the private fixture transport client, with a Brush-only directory."""
import importlib.util
from build import ROOT,BASE

spec=importlib.util.spec_from_file_location('brush_request',ROOT/'tools/performance/retained_integration/request.py')
client=importlib.util.module_from_spec(spec)
spec.loader.exec_module(client)
client.BASE=BASE
if __name__=='__main__':client.main()
