"""Typed adapter envelopes and real owned-worker failure/recovery over STDIO."""
import ctypes
from ctypes import wintypes
import json
import os
import sys
import time
from pathlib import Path
import unittest

TOOL = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(TOOL), str(TOOL/"tests")]
import anyio
from mcp import types
from mcp.shared.message import SessionMessage
import test_retrieval as fixtures
from test_transport import RawClient
from adapter import AdapterFailure, TOOLS, WIRE_LIMIT, WireWriter, failure, result
from contracts import SEARCH_SCHEMA, STATUS_SCHEMA


class ErrorContractTests(unittest.TestCase):
    def check_error(self, envelope, name, kind, code, rebuild=False):
        value = envelope["structuredContent"]
        self.assertTrue(envelope["isError"])
        self.assertEqual(value["schema"], SEARCH_SCHEMA if name == TOOLS[0] else STATUS_SCHEMA)
        self.assertFalse(value["ok"])
        self.assertEqual(value["error_type"], kind)
        self.assertEqual(value["exit_code"], code)
        self.assertEqual(value["rebuild_required"], rebuild)
        self.assertEqual(value["stale"], kind == "stale_evidence")
        self.assertEqual(value["results"], [])
        self.assertTrue(value["action"])
        self.assertEqual(json.loads(envelope["content"][0]["text"]), value)
        return value

    def test_explicit_mapping_including_original_io_regression(self):
        for name in TOOLS:
            for kind, code in (("io_failure",3),("invalid_input",2),("timeout",3),("busy",3),("response_too_large",2)):
                with self.subTest(name=name, kind=kind):
                    envelope = result(failure(kind, "Owned fixture failure", name)).model_dump(by_alias=True, exclude_unset=True, mode="json")
                    value = self.check_error(envelope, name, kind, code)
                    if kind in AdapterFailure.categories:
                        self.assertEqual(value["action"], AdapterFailure.categories[kind][1])
        with self.assertRaises(KeyError): failure("unknown_category", "Do not emit an unmapped error")

    def test_actual_envelope_size_fallback_preserves_each_operation_schema(self):
        class Sink:
            async def send(self, message): self.message = message
        async def check():
            for name in TOOLS:
                sink=Sink();body=result(failure("io_failure", "large fixture", name)).model_dump(by_alias=True, exclude_unset=True, mode="json")
                body["content"][0]["text"]="x"*WIRE_LIMIT
                message=SessionMessage(types.jsonrpc_message_adapter.validate_python({"jsonrpc":"2.0","id":1,"result":body},by_name=False))
                await WireWriter(sink).send(message)
                envelope=sink.message.message.model_dump(by_alias=True,exclude_unset=True,mode="json")["result"]
                self.check_error(envelope,name,"response_too_large",2)
        anyio.run(check)


class OwnedWorkerTests(unittest.TestCase):
    check_error = ErrorContractTests.check_error
    setUp = fixtures.RetrievalFixtures.setUp
    tearDown = fixtures.RetrievalFixtures.tearDown
    write = fixtures.RetrievalFixtures.write
    git = fixtures.RetrievalFixtures.git
    scan = fixtures.RetrievalFixtures.scan
    read_rows = fixtures.RetrievalFixtures.read_rows
    build = fixtures.RetrievalFixtures.build

    @unittest.skipUnless(os.name == "nt", "Windows owned-process fixture")
    def test_real_owned_worker_failure_both_tools_and_recovery(self):
        index=self.build()
        for name in TOOLS:
            with self.subTest(name=name):
                client=RawClient(self.root,index)
                try:
                    args={"query":"forRanges"} if name==TOOLS[0] else {"verify_sources":True}
                    client.send({"jsonrpc":"2.0","id":10,"method":"tools/call","params":{"name":name,"arguments":args}})
                    end=time.monotonic()+5;worker=None
                    while time.monotonic()<end:
                        starts=[line for line in client.stderr if "knowledge worker start pid=" in line]
                        if starts:
                            worker=int(starts[-1].split("pid=")[-1]);break
                        time.sleep(.001)
                    self.assertIsNotNone(worker)
                    # This PID comes from this private server's diagnostic pipe.
                    # Open and terminate only that verified owned worker.
                    kernel=ctypes.WinDLL("kernel32",use_last_error=True)
                    kernel.OpenProcess.argtypes=[wintypes.DWORD,wintypes.BOOL,wintypes.DWORD];kernel.OpenProcess.restype=wintypes.HANDLE
                    kernel.TerminateProcess.argtypes=[wintypes.HANDLE,wintypes.UINT]
                    kernel.WaitForSingleObject.argtypes=[wintypes.HANDLE,wintypes.DWORD]
                    kernel.CloseHandle.argtypes=[wintypes.HANDLE]
                    handle=kernel.OpenProcess(1|0x100000,False,worker)
                    self.assertTrue(handle)
                    try:
                        self.assertTrue(kernel.TerminateProcess(handle,7))
                        self.assertEqual(kernel.WaitForSingleObject(handle,3000),0)
                    finally:kernel.CloseHandle(handle)
                    self.check_error(client.receive(10)["result"],name,"io_failure",3)
                    recovered=client.call(name,args)["result"]
                    self.assertFalse(recovered["isError"]);self.assertTrue(recovered["structuredContent"]["ok"])
                    empty=client.call(arguments={"query":"noresultzxq123"})["result"]
                    self.assertFalse(empty["isError"]);self.assertEqual(empty["structuredContent"]["results"],[])
                finally:client.close()

    def test_invalid_stale_timeout_and_recovery_envelopes(self):
        index=self.build();client=RawClient(self.root,index)
        try:
            for name,args in ((TOOLS[0],{"query":"forRanges","top_k":True}),(TOOLS[1],{"verify_sources":1})):
                self.check_error(client.call(name,args)["result"],name,"invalid_input",2)
            path=self.root/self.current;original=path.read_bytes();path.write_bytes(original+b"changed\n")
            for name,args in ((TOOLS[0],{"query":self.current,"mode":"path"}),(TOOLS[1],{"verify_sources":True})):
                envelope=client.call(name,args)["result"]
                # Status aggregates parent failures and has no compatibility text
                # error wrapper fields beyond its documented source issue details.
                value=envelope["structuredContent"]
                self.assertTrue(envelope["isError"]);self.assertEqual(value["error_type"],"stale_evidence")
                self.assertEqual(value["exit_code"],3);self.assertTrue(value["rebuild_required"])
                self.assertTrue(value["stale"]);self.assertEqual(value.get("results",[]),[])
                self.assertEqual(value["schema"],SEARCH_SCHEMA if name==TOOLS[0] else STATUS_SCHEMA)
                self.assertTrue(value["action"])
            path.write_bytes(original)
            self.assertFalse(client.call("knowledge_status",{"verify_sources":True})["result"]["isError"])
        finally:client.close()
        client=RawClient(self.root,index,.001)
        try:
            for name,args in ((TOOLS[0],{"query":"forRanges"}),(TOOLS[1],{})):
                self.check_error(client.call(name,args)["result"],name,"timeout",3)
        finally:client.close()

    def test_busy_and_size_envelopes_through_stdio(self):
        index=self.build();client=RawClient(self.root,index)
        try:
            for request_id in range(10,20):
                name=TOOLS[request_id%2];args={"query":"forRanges"} if name==TOOLS[0] else {}
                client.send({"jsonrpc":"2.0","id":request_id,"method":"tools/call","params":{"name":name,"arguments":args}})
            busy=set()
            for _ in range(10):
                response=client.messages.get(timeout=15)
                value=response.get("result",{}).get("structuredContent",{})
                if value.get("error_type")=="busy":
                    name=TOOLS[response["id"]%2];self.check_error(response["result"],name,"busy",3);busy.add(name)
            self.assertEqual(busy,set(TOOLS))
            self.assertFalse(client.call("knowledge_status")["result"]["isError"])
        finally:client.close()
        self.definition["sources"][0]["applicability"]["limits"]="L"*120000
        import retrieval
        self.corpus.write_bytes(retrieval.encoded(self.definition));client=RawClient(self.root,self.build("oversize"))
        try:
            self.check_error(client.call(arguments={"query":self.current,"mode":"path"})["result"],TOOLS[0],"response_too_large",2)
            self.assertFalse(client.call(arguments={"query":self.history,"mode":"path"})["result"]["isError"])
        finally:client.close()
