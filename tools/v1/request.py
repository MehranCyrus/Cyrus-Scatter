"""Submit an isolated host fixture, with a bounded default response wait."""
import importlib.util
from build import ROOT,BASE
spec=importlib.util.spec_from_file_location('v1_request',ROOT/'tools/performance/retained_integration/request.py')
client=importlib.util.module_from_spec(spec);spec.loader.exec_module(client)
client.BASE=BASE/'hosts'
if __name__=='__main__':client.main()
