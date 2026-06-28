# Troubleshooting

## Plugin Installed But Devices Still Cannot Be Controlled

Symptom:

```text
mijia-control-codex@personal installed, enabled
python not found
mijia-control not on PATH
MIJIA_API_URL not set
MIJIA_TOKEN not set
127.0.0.1:5000 unreachable
```

Cause: Codex installed the plugin package, but the target machine does not yet have the upstream runtime and local credentials required by `.mcp.json`. The plugin never includes Python, upstream `mijia-control`, account tokens, device IDs, or a running web service.

Fix on Windows:

```powershell
cd path\to\MijiaPilotByCodexPlugin
powershell -ExecutionPolicy Bypass -File .\plugins\mijia-control-codex\scripts\setup-windows.ps1 -InstallPythonWithWinget
```

Then run:

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\mijia-control-codex\scripts\check-runtime.ps1
```

If plain `python` is still unavailable to Codex, copy the venv Python path printed by `setup-windows.ps1` into a local `.mcp.json` command override on that machine.

If the CLI is not on PATH but `check-runtime.ps1` reports `%USERPROFILE%\mijia-control\venv\Scripts\mijia-control.exe`, use that absolute path or activate the venv before running CLI commands.

After the upstream runtime is installed, let the plugin helper start the local service:

```powershell
C:\Users\<you>\mijia-control\venv\Scripts\python.exe .\plugins\mijia-control-codex\scripts\ensure_mijia_service.py
```

Or start the web service manually in a separate terminal:

```powershell
cd $env:USERPROFILE\mijia-control
.\venv\Scripts\python.exe run.py
```

Then log in. The plugin wrapper can reuse the CLI token file created by this command:

```powershell
.\venv\Scripts\mijia-control.exe login
```

If you prefer environment variables instead of the CLI token file, set them in the environment that launches Codex:

```powershell
$env:MIJIA_API_URL = "http://127.0.0.1:5000/api"
$env:MIJIA_TOKEN = "replace-with-local-jwt-access-token"
```

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

## Python Exists But Is The Windows Store Stub

Symptom: `python` exists, but it opens the Microsoft Store or fails before printing a version.

Fix:

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\mijia-control-codex\scripts\setup-windows.ps1 -InstallPythonWithWinget
```

The helper verifies that Python can actually execute `import sys` and has version 3.10 or newer. It also checks common Python install paths if PATH still points at a stub.

If Python is installed but the current Codex process still sees only `C:\Users\<you>\AppData\Local\Microsoft\WindowsApps\python.exe`, restart Codex after installing Python or add a local MCP server that points directly at the upstream venv Python:

```powershell
codex mcp add mijia-control --env MCP_TRANSPORT=stdio --env MIJIA_API_URL=http://127.0.0.1:5000/api -- C:\Users\<you>\mijia-control\venv\Scripts\python.exe C:\path\to\plugin\scripts\mijia-mcp-wrapper.py
```

## Authentication Errors

Symptom: MCP or CLI calls return unauthorized or token errors.

Fix:

```bash
mijia-control login
```

Then refresh `MIJIA_TOKEN` in the environment used by Codex.

## Web Service Unreachable

Symptom: connection refused to `127.0.0.1:5000`.

Fix with autostart:

```bash
python scripts/ensure_mijia_service.py
```

If the helper cannot find upstream, set the checkout path:

```bash
export MIJIA_CONTROL_DIR=/path/to/mijia-control
python scripts/ensure_mijia_service.py
```

Manual fix:

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

If you intentionally run a remote upstream service, the helper will not start a local service for that URL. Confirm the remote service separately.

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
