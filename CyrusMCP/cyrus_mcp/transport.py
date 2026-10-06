"""Authenticated loopback IPC, separate from MCP. No code or file execution endpoint."""
import hashlib
import hmac
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import queue
import secrets
import subprocess
import threading
import time
import urllib.request
import uuid

from .contracts import Fault, canonical, decode, fields, require


def private_directory(path):
    path = Path(path)
    path.mkdir(parents=True, exist_ok=True)
    if os.name == "nt":
        # Use the SID, not a localized group name. No credentials appear in output.
        import ctypes
        from ctypes import wintypes
        advapi = ctypes.WinDLL("advapi32", use_last_error=True)
        kernel = ctypes.WinDLL("kernel32", use_last_error=True)
        kernel.GetCurrentProcess.restype = wintypes.HANDLE
        advapi.OpenProcessToken.argtypes = [wintypes.HANDLE, wintypes.DWORD, ctypes.POINTER(wintypes.HANDLE)]
        advapi.GetTokenInformation.argtypes = [wintypes.HANDLE, ctypes.c_int, ctypes.c_void_p, wintypes.DWORD, ctypes.POINTER(wintypes.DWORD)]
        kernel.CloseHandle.argtypes = [wintypes.HANDLE]
        token = wintypes.HANDLE()
        if not advapi.OpenProcessToken(kernel.GetCurrentProcess(), 8, ctypes.byref(token)):
            raise OSError("Could not read current user token")
        try:
            size = wintypes.DWORD()
            advapi.GetTokenInformation(token, 1, None, 0, ctypes.byref(size))
            buffer = ctypes.create_string_buffer(size.value)
            if not advapi.GetTokenInformation(token, 1, buffer, size, ctypes.byref(size)):
                raise OSError("Could not read current user SID")
            sid_pointer = ctypes.cast(buffer, ctypes.POINTER(ctypes.c_void_p))[0]
            sid_text = wintypes.LPWSTR()
            advapi.ConvertSidToStringSidW.argtypes = [ctypes.c_void_p, ctypes.POINTER(wintypes.LPWSTR)]
            if not advapi.ConvertSidToStringSidW(sid_pointer, ctypes.byref(sid_text)):
                raise OSError("Could not format current user SID")
            try:
                result = subprocess.run(["icacls", str(path), "/inheritance:r", "/grant:r", f"*{sid_text.value}:(OI)(CI)F"], capture_output=True, creationflags=subprocess.CREATE_NO_WINDOW)
                if result.returncode:
                    raise OSError("Could not protect the local connection directory")
            finally:
                kernel.LocalFree.argtypes = [ctypes.c_void_p]
                kernel.LocalFree(ctypes.cast(sid_text, ctypes.c_void_p))
        finally:
            kernel.CloseHandle(token)
    else:
        path.chmod(0o700)
    return path


def default_directory():
    # MSIX clients can virtualize LocalAppData while native Max cannot see that
    # redirected location. A user-profile directory is shared by both processes.
    return Path.home() / ".cyrus-scatter" / "automation"


def signature(secret, stamp, nonce, data):
    return hmac.new(secret.encode(), (stamp+"\n"+nonce+"\n").encode()+data, hashlib.sha256).hexdigest()


class Ticket:
    def __init__(self, data):
        self.data, self.event = data, threading.Event()
        self.deadline, self.result = time.monotonic()+8, None


class Bridge:
    def __init__(self, directory, wake=None):
        self.directory = private_directory(directory)
        self.closed = False
        # Notification only: the caller must marshal to its UI thread. No host
        # methods or scene wrappers may be used by this HTTP worker.
        self.wake = wake
        self.lease = (self.directory/"connection.lock").open("a+b")
        if self.lease.seek(0,2) == 0:
            self.lease.write(b"0")
            self.lease.flush()
        self.lease.seek(0)
        try:
            if os.name == "nt":
                import msvcrt
                msvcrt.locking(self.lease.fileno(),msvcrt.LK_NBLCK,1)
            else:
                import fcntl
                fcntl.flock(self.lease,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except OSError as exc:
            self.lease.close()
            raise Fault("HOST_BUSY","Another Max session owns this connection folder. Close its Automation panel first, or use a separate folder.") from exc
        self.queue = queue.Queue(maxsize=16)
        self.secret = secrets.token_hex(32)
        self.nonces, self.lock = {}, threading.Lock()
        self.slots = threading.BoundedSemaphore(8)
        owner = self

        class Server(ThreadingHTTPServer):
            daemon_threads = True
            allow_reuse_address = False
            def process_request(self, request, address):
                if not owner.slots.acquire(False):
                    self.shutdown_request(request)
                    return
                try:
                    super().process_request(request, address)
                except BaseException:
                    owner.slots.release()
                    raise
            def process_request_thread(self, request, address):
                try:
                    super().process_request_thread(request,address)
                finally:
                    owner.slots.release()

        class Handler(BaseHTTPRequestHandler):
            def setup(self):
                super().setup()
                self.connection.settimeout(3)
            def log_message(self, *_):
                pass
            def do_POST(self):
                try:
                    require(not self.headers.get("Transfer-Encoding"), "Chunked requests are unsupported")
                    require(len(self.headers.get_all("Content-Length", [])) == 1, "Length required")
                    length = int(self.headers["Content-Length"])
                    require(0 < length <= 65536, "Request too large", "BUDGET_EXCEEDED")
                    data = self.rfile.read(length)
                    require(len(data) == length, "Truncated request")
                    require(self.path == "/rpc" and not self.headers.get("Origin"), "Invalid local request")
                    require(self.headers.get("Host") == f"127.0.0.1:{owner.server.server_port}", "Invalid host")
                    stamp, nonce = self.headers.get("X-Cyrus-Time", ""), self.headers.get("X-Cyrus-Nonce", "")
                    require(abs(time.time()-float(stamp)) <= 30 and len(nonce) == 32, "Expired authentication")
                    expected = signature(owner.secret, stamp, nonce, data)
                    require(hmac.compare_digest(expected, self.headers.get("X-Cyrus-Signature", "")), "Authentication failed")
                    with owner.lock:
                        owner.nonces = {k:v for k,v in owner.nonces.items() if time.time()-v < 60}
                        require(nonce not in owner.nonces and len(owner.nonces) < 1024, "Replayed request")
                        owner.nonces[nonce] = time.time()
                    payload = decode(data)
                    fields(payload, ("method", "args"))
                    ticket = Ticket(payload)
                    try:
                        with owner.lock:
                            require(not owner.closed, "The local connection is closing", "HOST_BUSY")
                            owner.queue.put_nowait(ticket)
                            wake=owner.wake
                    except queue.Full:
                        raise Fault("HOST_BUSY", "Host request queue is full")
                    if wake is not None:
                        try:
                            wake()
                        except Exception:
                            ticket.result = Fault("HOST_BUSY", "The host dispatcher is unavailable").result()
                            ticket.event.set()
                    if not ticket.event.wait(9):
                        raise Fault("OUTCOME_UNKNOWN", "Host response timed out. Reconcile any apply using the same key; no automatic retry was performed")
                    answer = ticket.result
                except Fault as exc:
                    answer = exc.result()
                except (ValueError, OSError):
                    answer = Fault("INVALID_PLAN", "Malformed local request").result()
                raw = canonical(answer).encode()
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(raw)))
                self.send_header("Connection", "close")
                self.end_headers()
                try:
                    self.wfile.write(raw)
                except OSError:
                    pass

        self.server = Server(("127.0.0.1", 0), Handler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True, name="Cyrus local IPC")
        self.thread.start()
        self.descriptor = self.directory / "connection.json"
        self.descriptor.write_text(canonical({"protocol": 1, "port": self.server.server_port, "secret": self.secret, "pid": os.getpid()}), encoding="utf-8")

    def drain_one(self, service):
        try:
            ticket = self.queue.get_nowait()
        except queue.Empty:
            return False
        if ticket.event.is_set():
            return True  # Failed wake/closed tickets must never execute later.
        try:
            if ticket.deadline < time.monotonic():
                raise Fault("HOST_BUSY", "Request expired before host admission")
            if service.host.busy():
                raise Fault("HOST_BUSY", "Max is in a modal, render, animation or transaction state")
            ticket.result = service.dispatch(ticket.data["method"], ticket.data["args"])
        except Fault as exc:
            ticket.result = exc.result()
        except Exception:
            ticket.result = Fault("HOST_ERROR", "Host inspection failed; see the local panel").result()
            import traceback
            (self.directory/"host-error.log").write_text(traceback.format_exc(),encoding="utf-8")
        finally:
            ticket.event.set()
        return True

    def close(self):
        if self.closed:
            return
        with self.lock:
            self.closed=True
            self.wake=None
            while True:
                try:
                    ticket=self.queue.get_nowait()
                except queue.Empty:
                    break
                ticket.result=Fault("HOST_BUSY", "The local connection closed before admission").result()
                ticket.event.set()
        self.server.shutdown()
        self.server.server_close()
        try:
            stored = decode(self.descriptor.read_bytes())
            if stored["secret"] == self.secret:
                self.descriptor.unlink()
        except (OSError, Fault):
            pass
        finally:
            self.lease.close()


class Client:
    def __init__(self, directory=None):
        self.directory = Path(directory) if directory else default_directory()
    def call(self, method, **args):
        try:
            config = decode((self.directory/"connection.json").read_bytes())
        except (OSError, Fault) as exc:
            raise Fault("NOT_CONNECTED", "Open the Cyrus Automation panel in Max and connect") from exc
        require(config.get("protocol") == 1 and type(config.get("port")) is int and 1024 <= config["port"] <= 65535, "Invalid connection descriptor")
        data = canonical({"method":method,"args":args}).encode()
        require(len(data) <= 65536, "Request exceeds its byte budget", "BUDGET_EXCEEDED")
        stamp, nonce = str(time.time()), uuid.uuid4().hex
        request = urllib.request.Request(f"http://127.0.0.1:{config['port']}/rpc", data=data, headers={
            "Content-Type":"application/json", "X-Cyrus-Time":stamp,"X-Cyrus-Nonce":nonce,
            "X-Cyrus-Signature":signature(config["secret"],stamp,nonce,data)})
        # Explicitly disable inherited proxies for local scene IPC.
        try:
            with urllib.request.build_opener(urllib.request.ProxyHandler({})).open(request,timeout=12) as response:
                result = decode(response.read(3_000_001), 3_000_000)
        except OSError as exc:
            raise Fault("OUTCOME_UNKNOWN", "Local connection interrupted. For an apply request, reconcile using the same idempotency key; never create a new key automatically.") from exc
        return result
