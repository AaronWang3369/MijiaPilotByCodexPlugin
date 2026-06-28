# Verification

## Local Plugin Checks

From the plugin root:

```bash
node scripts/verify-plugin.mjs
```

Expected result:

```text
verify-plugin: ok
```

This checks:

- `.codex-plugin/plugin.json` exists and parses as JSON.
- `plugin.json` includes required public plugin metadata.
- `skills` points to `./skills/`.
- `mcpServers` points to `./.mcp.json`.
- `.mcp.json` declares `mijia-control`.
- `skills/mijia-control/SKILL.md` has valid frontmatter.
- the skill contains the no-bypass rule.
- config templates do not contain obvious committed secrets.
- marketplace entry points to `./plugins/mijia-control-codex`.

## Windows Runtime Checks

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\mijia-control-codex\scripts\check-runtime.ps1
```

Expected healthy output includes:

```text
[OK] git
[OK] python
[OK] mijia-control Python modules
[OK] MIJIA_API_URL
[OK] MIJIA_TOKEN
```

If Python or `mijia-control Python modules` is missing, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\mijia-control-codex\scripts\setup-windows.ps1
```

## Codex Manifest Validator

If available, run the Codex plugin creator validator:

```bash
python path/to/plugin-creator/scripts/validate_plugin.py path/to/plugins/mijia-control-codex
```

The local plugin was shaped to satisfy the current plugin creator validator contract:

- semver version.
- required `author.name`.
- required `interface` fields.
- `defaultPrompt` array.
- companion `.mcp.json` with `mcpServers` wrapper.

## MCP Startup Check

From an environment where upstream `mijia-control` is installed:

```bash
python -c "import mcp_server; print('mcp_server import ok')"
python -m mcp_server
```

The second command starts a stdio MCP server and waits for MCP input. Stop it with `Ctrl+C` after confirming it starts.

For a stronger local MCP check, use the MCP Python SDK to initialize a stdio client session and list tools. The expected tool names are:

```text
list_devices
get_device
get_property
set_property
run_action
list_scenes
run_scene
list_homes
get_home
list_ble_devices
get_ble_sensor
get_ble_readings
```

## CLI Check

Read-only commands:

```bash
mijia-control --help
mijia-control whoami
mijia-control xiaomi status
mijia-control device list
```

## Real Device Verification Gap

Real device operations require:

- a valid Xiaomi account binding in upstream `mijia-control`;
- reachable devices;
- user permission to control those devices;
- a fresh local `MIJIA_TOKEN`.

Without those, only plugin structure, manifest, skill loading, MCP startup shape, and CLI/MCP importability can be verified.
