import concurrent.futures
import json
import threading
import time
import urllib.request
import uuid
import pytest
from cyrus_mcp.contracts import canonical,Fault
from cyrus_mcp.transport import Bridge,Client,signature


@pytest.fixture
def bridge(tmp_path):
    value=Bridge(tmp_path/"private")
    yield value
    value.close()


def request(bridge, data=None, headers=None):
    raw=canonical(data or {"method":"connection.get_status","args":{}}).encode()
    nonce=uuid.uuid4().hex
    stamp=str(time.time())
    h={"Content-Type":"application/json","X-Cyrus-Time":stamp,"X-Cyrus-Nonce":nonce,"X-Cyrus-Signature":signature(bridge.secret,stamp,nonce,raw)}
    if headers:h.update(headers)
    return urllib.request.Request(f"http://127.0.0.1:{bridge.server.server_port}/rpc",data=raw,headers=h)


def send(request):
    with urllib.request.build_opener(urllib.request.ProxyHandler({})).open(request,timeout=12) as response:
        return json.loads(response.read())


@pytest.mark.parametrize("headers",[{"X-Cyrus-Signature":"wrong"},{"Origin":"https://attacker.invalid"},{"Host":"attacker.invalid"},{"X-Cyrus-Time":"0"},{"Transfer-Encoding":"chunked"}])
def test_auth_and_browser_requests_rejected(bridge,headers):
    assert not send(request(bridge,headers=headers))["ok"]
    assert bridge.queue.empty()


def test_authenticated_calls_run_on_dispatch_thread_and_nonce_replay_fails(bridge):
    main=threading.get_ident()
    class Host:
        def busy(self):return False
    class Service:
        host=Host()
        def dispatch(self,method,args):
            assert threading.get_ident()==main
            return {"ok":True,"method":method}
    req=request(bridge)
    with concurrent.futures.ThreadPoolExecutor() as pool:
        future=pool.submit(send,req)
        deadline=time.monotonic()+3
        while bridge.queue.empty() and time.monotonic()<deadline:time.sleep(.01)
        bridge.drain_one(Service())
        assert future.result()["ok"]
    assert not send(req)["ok"]


def test_expired_queued_requests_never_dispatch(bridge):
    from cyrus_mcp.transport import Ticket
    ticket=Ticket({"method":"scatter.apply_plan","args":{}})
    ticket.deadline=time.monotonic()-1
    bridge.queue.put(ticket)
    bridge.drain_one(None)
    assert ticket.result["error"]["code"]=="HOST_BUSY"


def test_missing_connection_reports_actionable_error(tmp_path):
    with pytest.raises(Fault,match="Open the Cyrus"):Client(tmp_path).call("connection.get_status")


def test_two_max_sessions_cannot_silently_replace_pairing(bridge):
    with pytest.raises(Fault,match="Another Max session"):
        Bridge(bridge.directory)
    bridge.close()
    replacement=Bridge(bridge.directory)
    replacement.close()


def test_wake_signals_work_without_executing_host_on_network_thread(tmp_path):
    ready=threading.Event()
    calls=[]
    main=threading.get_ident()
    def wake():
        calls.append(threading.get_ident())
        ready.set()
    class Service:
        class host:
            @staticmethod
            def busy():
                assert threading.get_ident()==main
                return False
        def dispatch(self,method,args):
            assert threading.get_ident()==main
            return {"ok":True}
    with concurrent.futures.ThreadPoolExecutor() as pool:
        bridge=Bridge(tmp_path/"wake",wake=wake)
        try:
            assert not send(request(bridge,headers={"X-Cyrus-Signature":"wrong"}))["ok"]
            assert not ready.is_set()
            future=pool.submit(send,request(bridge))
            assert ready.wait(3)
            assert calls[0]!=main
            assert not future.done()
            assert bridge.drain_one(Service())
            assert future.result(timeout=3)["ok"]
            assert bridge.drain_one(Service()) is False
        finally:
            bridge.close()


def test_failed_wake_never_applies_later(tmp_path):
    def fail():
        raise RuntimeError("UI object closed")
    bridge=Bridge(tmp_path/"failed-wake",wake=fail)
    try:
        result=send(request(bridge,data={"method":"scatter.apply_plan","args":{}}))
        assert result["error"]["code"]=="HOST_BUSY"
        assert bridge.drain_one(None) is True
        assert bridge.queue.empty()
    finally:
        bridge.close()


def test_closing_releases_queued_caller_without_dispatch(tmp_path):
    ready=threading.Event()
    bridge=Bridge(tmp_path/"close",wake=ready.set)
    with concurrent.futures.ThreadPoolExecutor() as pool:
        try:
            future=pool.submit(send,request(bridge))
            assert ready.wait(3)
            bridge.close()
            assert future.result(timeout=3)["error"]["code"]=="HOST_BUSY"
            assert bridge.queue.empty()
        finally:
            bridge.close()
