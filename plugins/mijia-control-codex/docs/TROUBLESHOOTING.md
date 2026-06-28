# Troubleshooting

## Plugin Installed But Devices Still Cannot Be Controlled

Symptom:

```text
mijia-control-codex@personal installed, enabled
python not found
mijia-control not on PATH
```

Cause: Codex installed the plugin package, but the target machine does not yet have the upstream runtime required by `.mcp.json`.

Fix on Windows:

```powershell
cd path\to\MijiaPilotByCodexPlugin
powershell -ExecutionPolicy Bypass -File .\plugins\mijia-control-codex\scripts\setup-windows.ps1
```

Then run:

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\mijia-control-codex\scripts\check-runtime.ps1
```

If plain `python` is still unavailable to Codex, copy the venv Python path printed by `setup-windows.ps1` into a local `.mcp.json` command override on that machine.

Start a new Codex thread after fixing the runtime so the plugin Skill/MCP configuration is loaded.

## Codex Cannot Start The MCP Server

Symptom:

```text
No module named mcp_server
```

Cause: the `python` command used by Codex cannot import upstream `mijia-control`.

Fix:

```bash
cd path/to/mijia-control
pip install -e ".[mcp]"
python -c "import mcp_server; print('ok')"
```

If the active Python is a venv, update your local MCP config to use that venv Python.

On Windows, the command usually looks like:

```json
"command": "C:\\Users\\Administrator\\mijia-control\\venv\\Scripts\\python.exe"
```

Keep this as local machine configuration; do not publish it.

## Authentication Errors

Symptom: MCP or CLI calls return unauthorized or token errors.

Fix:

```bash
mijia-control login
```

Then refresh `MIJIA_TOKEN` in the environment used by Codex.

## Web Service Unreachable

Symptom: connection refused to `127.0.0.1:5000`.

Fix:

```bash
cd path/to/mijia-control
python run.py
```

Check that `MIJIA_API_URL` points to the running service:

```bash
echo "$MIJIA_API_URL"
```

Windows PowerShell:

```powershell
$env:MIJIA_API_URL
```

## Device IDs Or Property Names Are Unknown

Do not guess. Discover them through upstream:

```bash
mijia-control device list
mijia-control device show <did>
```

Or use MCP:

- `list_devices`
- `get_device`

## Device-Changing Operation Failed

Check supported properties and actions first:

```bash
mijia-control device show <did>
```

Then retry only with a property or action shown by upstream `mijia-control`.

## Real Device Verification Is Not Available

If no real Xiaomi account or device is available, do not claim device control is verified. Validate only:

- plugin manifest;
- skill readability;
- `.mcp.json` shape;
- upstream CLI import/startup;
- upstream MCP import/startup.
