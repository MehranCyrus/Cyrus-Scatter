"""One bounded read-only engine request. Never interprets retrieved instructions."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from adapter_process import deny_network
from contracts import SEARCH_SCHEMA, STATUS_SCHEMA, IncompatibleIndex, error_response
from retrieval import encoded, search
from status import index_status


def main():
    sys.addaudithook(deny_network)
    request = json.loads(sys.stdin.buffer.read(8193))
    name, args = request["name"], request["arguments"]
    schema = SEARCH_SCHEMA if name == "knowledge_search" else STATUS_SCHEMA
    try:
        if name == "knowledge_search":
            filters = {key: args[key] for key in ("component", "role", "knowledge_status") if key in args}
            value = search(Path(request["index"]), args["query"], args.get("top_k", 5),
                           args.get("mode", "keyword"), filters, expected_root=Path(request["root"]))
        else:
            value = index_status(Path(request["index"]), args.get("verify_sources", False), Path(request["root"]))
        if value["index_generation"] != request["generation"]:
            raise IncompatibleIndex("bound generation identity changed; restart with an explicit reviewed generation")
    except (ValueError, OSError) as exc:
        value = error_response(exc, schema)
    sys.stdout.buffer.write(encoded(value))


if __name__ == "__main__":
    main()
