"""Two-phase installed-package test; approve the private fixture through Max UI.

This harness is not shipped. Its setup command may reset only the isolated
qualification scene. Between prepare/apply, click Approve in that scene's panel.
"""
import argparse
import asyncio
import base64
import json
from pathlib import Path
import sys
import uuid

from mcp import Client
from mcp.client.stdio import StdioServerParameters
from cyrus_mcp.transport import Client as HostClient
from qualify import Qualification


async def run(folder, phase):
    q = Qualification(folder)
    q.client = HostClient()
    path = q.folder / "installed-acceptance.json"
    evidence = json.loads(path.read_text()) if path.exists() else {}
    params = StdioServerParameters(command=sys.executable, args=["-m", "cyrus_mcp.server"])
    async with Client(params) as client:
        async def call(name, **args):
            result = await client.call_tool(name, args)
            assert not result.is_error, result
            assert result.structured_content["ok"], result
            return result.structured_content

        if phase == "prepare":
            connection = await call("connection_get_status")
            assert connection["scope_id"] is None, "Fresh package must not auto-enroll"
            q.local("setup")
            connection = await call("connection_get_status")
            context = await call("scene_get_context", scope_id=connection["scope_id"])
            plan = q.plan(context, count=400, layers=3)
            plan["name"] = "Installed package • artist approval test"
            validation = await call("scatter_validate_plan", plan=plan)
            args = {key: validation[key] for key in ("validation_id", "digest", "scene_epoch", "scene_revision")}
            args["idempotency_key"] = uuid.uuid4().hex
            denied = await client.call_tool("scatter_apply_plan", args)
            assert denied.is_error and denied.structured_content["error"]["code"] == "APPROVAL_REQUIRED", denied
            evidence = {"python": sys.executable, "tools": [t.name for t in (await client.list_tools()).tools],
                        "fresh_install_not_enrolled": True, "before_local_approval_rejected": True,
                        "request": args, "viewport_id": context["viewport_id"]}
        elif phase == "apply":
            args = evidence["request"]
            operation = (await call("scatter_apply_plan", **args))["operation"]
            for _ in range(20):
                operation = (await call("scatter_get_status", scene_epoch=args["scene_epoch"], operation_id=operation["operation_id"]))["operation"]
                if operation["state"] not in ("queued", "running"):
                    break
                await asyncio.sleep(.2)
            assert operation["state"] == "succeeded", operation
            assert operation["result"]["emitted"] == 1200, operation
            assert (await call("scatter_apply_plan", **args))["operation"] == operation
            capture = await client.call_tool("scene_capture_viewport", {
                "scene_epoch": args["scene_epoch"], "scene_revision": operation["scene_revision"],
                "viewport_id": evidence["viewport_id"], "generation_id": operation["result"]["generation_id"]})
            assert not capture.is_error, capture
            images = [c for c in capture.content if c.type == "image"]
            assert len(images) == 1
            png = base64.b64decode(images[0].data)
            assert png.startswith(b"\x89PNG")
            (q.folder / "installed-capture.png").write_bytes(png)
            evidence.update(after_ui_approval_succeeded=True, exact_retry=True, operation=operation,
                            image_bytes=len(png), image_content=True, redraw_enabled=not q.local("snapshot")["redraw_disabled"])
            assert evidence["redraw_enabled"]
        elif phase == "playing":
            result = await client.call_tool("connection_get_status", {})
            assert result.is_error and result.structured_content["error"]["code"] == "HOST_BUSY", result
            evidence["native_playback_admission_rejected"] = True
        elif phase == "stopped":
            assert (await call("connection_get_status"))["scope_id"] is not None
            evidence["playback_stop_restores_admission"] = True
        elif phase == "closed":
            result = await client.call_tool("connection_get_status", {})
            assert result.is_error and result.structured_content["error"]["code"] == "NOT_CONNECTED", result
            evidence["escape_disconnects_ipc"] = True
        elif phase == "reopened":
            assert (await call("connection_get_status"))["scope_id"] is None
            evidence["script_reopens_without_enrollment"] = True
        else:
            raise ValueError(phase)
    path.write_text(json.dumps(evidence, indent=2))
    print(json.dumps({"phase": phase, "passed": True, "evidence": str(path)}, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("folder", type=Path)
    parser.add_argument("phase", choices=("prepare", "apply", "playing", "stopped", "closed", "reopened"))
    options = parser.parse_args()
    asyncio.run(run(options.folder, options.phase))
