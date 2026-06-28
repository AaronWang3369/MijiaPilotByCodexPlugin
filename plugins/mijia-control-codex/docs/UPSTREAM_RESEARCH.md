# Upstream Research Notes

Target project:

```text
https://github.com/handsomejustin/mijia-control
```

Observed revision:

```text
commit: bb5ec6e605c0e452bafd60c4ffe9147e785a1bf2
date: 2026-05-24 02:28:10 +0800
subject: fix: graceful handling of missing device spec data; add fan category support
```

## Repository Structure

Observed files and folders relevant to this plugin:

- `pyproject.toml`
- `mijia_cli.py`
- `mcp_server/server.py`
- `mcp_server/__main__.py`
- `mcp_server/__init__.py`
- `run.py`
- `.env.example`
- `config/__init__.py`
- `app/api/`
- `migrations/`
- `Dockerfile.mcp`
- `README_EN.md`

## Dependencies

`pyproject.toml` declares:

- Python `>=3.10`
- core Flask, SQLAlchemy, JWT, SocketIO, Click, HTTP, and `mijiaAPI` dependencies
- optional `mcp` extra with `mcp[cli]>=1.6` and `httpx>=0.27`
- optional HomeKit and BLE extras

## License

The observed upstream `LICENSE` file is MIT License, with copyright attributed to Justin Gu.

## Entry Points

`pyproject.toml` declares:

```toml
[project.scripts]
mijia-control = "mijia_cli:cli"
mijia-mcp = "mcp_server:mcp.run"
```

`mcp_server/__main__.py` runs:

```python
mcp.run(transport=os.environ.get("MCP_TRANSPORT", "stdio"))
```

The plugin uses `python -m mcp_server` because it preserves the upstream module startup path and the upstream default `stdio` transport expected by Codex.

## Environment Variables

Observed upstream variables:

- `MIJIA_API_URL`, default `http://127.0.0.1:5000/api`
- `MIJIA_TOKEN`
- `MCP_TRANSPORT`, default `stdio` in `mcp_server/__main__.py`
- `MCP_HOST`, default `127.0.0.1` in `mcp_server/server.py`
- `MCP_PORT`, default `8000` in `mcp_server/server.py`

The plugin forwards `MIJIA_API_URL` and `MIJIA_TOKEN` with Codex `env_vars` and sets `MCP_TRANSPORT=stdio` as a literal non-secret value.

## CLI Surface

Observed CLI groups:

- `login`
- `logout`
- `whoami`
- `xiaomi`
- `device`
- `scene`
- `home`
- `ble`

Observed device and scene actions include:

- `mijia-control device list`
- `mijia-control device show <did>`
- `mijia-control device get <did> <prop_name>`
- `mijia-control device set <did> <prop_name> <value>`
- `mijia-control device action <did> <action_name>`
- `mijia-control scene list`
- `mijia-control scene run <scene_id>`

## MCP Tool Surface

Observed MCP tools:

- `list_devices`
- `get_device`
- `get_property`
- `set_property`
- `run_action`
- `list_scenes`
- `run_scene`
- `list_homes`
- `get_home`
- `list_ble_devices`
- `get_ble_sensor`
- `get_ble_readings`

## Local Verification Performed

Using a temporary virtual environment:

```text
pip install -e ".[mcp]"
```

Verified:

- upstream dependencies installed successfully;
- `mijia-control --help` showed CLI groups;
- `import mcp_server` and `import mijia_cli` succeeded;
- MCP stdio client `initialize` and `list_tools` succeeded;
- `list_tools` returned the 12 tools listed above.

Not verified:

- Xiaomi account binding;
- real device discovery;
- property writes;
- device actions;
- scene execution;
- BLE hardware scanning.

Those require user-owned credentials and physical devices.
