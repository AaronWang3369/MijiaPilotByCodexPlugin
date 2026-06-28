"""Start upstream mijia-control MCP with CLI token fallback and service autostart.

The upstream CLI stores login data in ~/.config/mijia-control/token.json, but
the upstream MCP server currently reads MIJIA_TOKEN only from the environment.
This wrapper keeps all device-facing behavior in upstream mijia-control while
allowing Codex MCP startup to reuse the token created by `mijia-control login`.
It may also start the local upstream Flask service before launching MCP.
"""

from __future__ import annotations

import json
import os
import runpy
import sys
from pathlib import Path

try:
    from ensure_mijia_service import ensure_service
except ImportError:
    ensure_service = None  # type: ignore[assignment]


def _load_cli_token() -> str | None:
    token_file = Path.home() / ".config" / "mijia-control" / "token.json"
    if not token_file.exists():
        return None

    try:
        data = json.loads(token_file.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None

    token = data.get("token")
    if isinstance(token, str) and token.strip():
        return token
    return None


def main() -> None:
    os.environ.setdefault("MCP_TRANSPORT", "stdio")
    os.environ.setdefault("MIJIA_API_URL", "http://127.0.0.1:5000/api")

    if not os.environ.get("MIJIA_TOKEN"):
        token = _load_cli_token()
        if token:
            os.environ["MIJIA_TOKEN"] = token

    if ensure_service:
        service_ok = ensure_service(api_url=os.environ["MIJIA_API_URL"], quiet=True, stream=sys.stderr)
        if not service_ok:
            print(
                "mijia-control service is not reachable. MCP will still start, but tool calls may fail.",
                file=sys.stderr,
            )

    runpy.run_module("mcp_server", run_name="__main__")


if __name__ == "__main__":
    main()
