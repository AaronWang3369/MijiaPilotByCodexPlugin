---
name: mijia-control
description: Use whenever a user asks Codex to inspect, control, automate, troubleshoot, or document Xiaomi/Mijia/Mi Home smart-home devices. This skill requires all Xiaomi/Mijia device actions to go through the upstream mijia-control CLI or MCP server only.
---

# Mijia Control

This plugin exists to enforce one integration boundary: when a task involves Xiaomi, Mijia, Mi Home, or Xiaomi smart-home devices, Codex must use `mijia-control` as the only device-facing interface.

Do not call Xiaomi Cloud, Mi Home private APIs, device LAN protocols, HomeKit, BLE libraries, browser sessions, mobile apps, or raw HTTP endpoints directly unless that call is made by the upstream `mijia-control` project through its documented CLI, REST-backed CLI, or MCP server. If the user asks to bypass `mijia-control`, explain that this plugin does not allow that path.

## Verified Upstream Shape

The plugin was built against `handsomejustin/mijia-control` as observed at commit `bb5ec6e605c0e452bafd60c4ffe9147e785a1bf2` dated `2026-05-24`.

Observed entry points:

- Package name: `mijia-control`
- Python requirement: `>=3.10`
- CLI console script: `mijia-control = mijia_cli:cli`
- MCP console script: `mijia-mcp = mcp_server:mcp.run`
- MCP module entry: `python -m mcp_server`
- MCP default transport: `stdio`, controlled by `MCP_TRANSPORT`
- API base env var: `MIJIA_API_URL`, defaulting upstream to `http://127.0.0.1:5000/api`
- API token env var: `MIJIA_TOKEN`

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

Observed CLI groups:

- `mijia-control login`, `logout`, `whoami`
- `mijia-control xiaomi status`, `xiaomi unlink`
- `mijia-control device list`, `show`, `get`, `set`, `action`
- `mijia-control scene list`, `scene run`
- `mijia-control home list`, `home show`
- `mijia-control ble scan`, `register`, `list`, `readings`

## Required Workflow

1. Confirm that the user is asking about Xiaomi/Mijia smart-home work.
2. Use only one of these paths:
   - MCP tools exposed by this plugin's `mijia-control` MCP server.
   - The upstream `mijia-control` CLI.
   - The upstream `python -m mcp_server` server process.
3. Prefer read-only commands first: list homes, list devices, inspect device details, read current properties.
4. Before changing real devices, state the intended target and action in concrete terms.
5. Never invent device IDs, home IDs, scene IDs, property names, or action names. Discover them with `list_devices`, `get_device`, `list_scenes`, or the CLI equivalents.
6. Do not expose or repeat `MIJIA_TOKEN`, Xiaomi account credentials, QR payloads, home IDs, device IDs, or scene IDs in final answers unless the user explicitly asks for local debugging data and sharing it is necessary.

## Safe Command Examples

```bash
mijia-control whoami
mijia-control xiaomi status
mijia-control home list
mijia-control device list
mijia-control scene list
```

## Device-Changing Command Examples

Use these only after confirming the specific device or scene from `mijia-control` output:

```bash
mijia-control device get <did> <prop_name>
mijia-control device set <did> <prop_name> <value>
mijia-control device action <did> <action_name>
mijia-control scene run <scene_id>
```

## MCP Startup

Codex should start the MCP server through the plugin `.mcp.json`:

```bash
python -m mcp_server
```

Required environment:

```bash
MIJIA_API_URL=http://127.0.0.1:5000/api
MCP_TRANSPORT=stdio
```

The upstream MCP server reads `MIJIA_TOKEN` from the environment. On machines configured with the optional `scripts/mijia-mcp-wrapper.py`, the wrapper can reuse the upstream CLI token file created by `mijia-control login` at `~/.config/mijia-control/token.json`. The upstream Flask service must already be running and reachable at `MIJIA_API_URL`.

## Failure Handling

- If `mijia-control` is missing, tell the user to install upstream with `pip install -e ".[mcp]"` from a local clone.
- On Windows, if `python`, `%USERPROFILE%\mijia-control\venv`, or `mcp_server` is missing, run `powershell -ExecutionPolicy Bypass -File .\plugins\mijia-control-codex\scripts\setup-windows.ps1 -InstallPythonWithWinget` from the plugin repository root, then run `scripts\check-runtime.ps1`.
- If plain `python` is missing but `%USERPROFILE%\mijia-control\venv\Scripts\python.exe` exists, point the local `.mcp.json` command at that venv Python path.
- If `MIJIA_TOKEN` is missing but the CLI token file exists, use the plugin wrapper or upstream CLI rather than asking the user to paste token values.
- If neither `MIJIA_TOKEN` nor the CLI token file exists, explain that the user must start upstream `mijia-control` and log in locally.
- If the MCP server starts but tool calls fail with authentication errors, ask the user to refresh `MIJIA_TOKEN` through `mijia-control login`.
- If device-changing calls fail, inspect device detail and supported properties/actions through `get_device` before retrying.
- If real devices or a Xiaomi account are unavailable, report that real-device verification is not possible instead of claiming success.
