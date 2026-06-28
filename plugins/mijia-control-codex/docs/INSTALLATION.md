# Installation

## Prerequisites

- Codex with plugin support.
- Python 3.10 or newer.
- A local clone or installation of `handsomejustin/mijia-control`.
- A local upstream `mijia-control` checkout. The plugin helper can start the upstream web service automatically when `MIJIA_API_URL` points to localhost.
- A local JWT access token from the upstream service, either in `MIJIA_TOKEN` or in the CLI token file created by `mijia-control login`.

`codex plugin list` showing this plugin as installed and enabled is not enough for device control. It only confirms Codex can load the plugin package. The machine also needs Python, upstream `mijia-control`, a running upstream web service, and local credentials.

## Install Upstream mijia-control

```bash
git clone https://github.com/handsomejustin/mijia-control.git
cd mijia-control
python -m venv venv
source venv/bin/activate
pip install -e ".[mcp]"
```

Windows PowerShell:

```powershell
git clone https://github.com/handsomejustin/mijia-control.git
cd mijia-control
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -e ".[mcp]"
```

Windows helper:

```powershell
cd path\to\MijiaPilotByCodexPlugin
powershell -ExecutionPolicy Bypass -File .\plugins\mijia-control-codex\scripts\setup-windows.ps1 -InstallPythonWithWinget
```

The helper checks Git, finds a real Python 3.10+ interpreter, optionally installs Python 3.12 with `winget`, clones upstream `mijia-control` to `%USERPROFILE%\mijia-control`, creates a venv, installs `.[mcp]`, verifies imports, and prints the venv Python path.

## Configure Upstream

Follow the upstream README to configure `.env`, initialize the database, register a local user, and bind a Xiaomi account.

The upstream project currently provides `.env.example` with settings such as:

- `FLASK_APP=app:create_app`
- `FLASK_ENV=development`
- `SECRET_KEY`
- `JWT_SECRET_KEY`
- `DATABASE_URL`
- `GO2RTC_URL`
- optional HomeKit and BLE settings

## Start Or Autostart The Service

You can start the upstream service manually:

```bash
cd path/to/mijia-control
python run.py
```

Or let the plugin helper start the local service:

```bash
cd path/to/MijiaPilotByCodexPlugin/plugins/mijia-control-codex
python scripts/ensure_mijia_service.py
```

On Windows, use the upstream venv Python if plain `python` is not visible to Codex:

```powershell
cd path\to\MijiaPilotByCodexPlugin\plugins\mijia-control-codex
C:\Users\you\mijia-control\venv\Scripts\python.exe .\scripts\ensure_mijia_service.py
```

Optional local environment variables:

```bash
export MIJIA_CONTROL_DIR=/path/to/mijia-control
export MIJIA_CONTROL_PYTHON=/path/to/mijia-control/venv/bin/python
export MIJIA_CONTROL_AUTOSTART=1
```

Set `MIJIA_CONTROL_AUTOSTART=0` only if you want to manage the service manually.

## Obtain A Token

Use the upstream CLI:

```bash
mijia-control login
```

Or use the upstream JWT API:

```bash
curl -X POST http://127.0.0.1:5000/api/auth/jwt/login \
  -H "Content-Type: application/json" \
  -d '{"username":"your-user","password":"your-password"}'
```

Set local environment variables:

```bash
export MIJIA_API_URL=http://127.0.0.1:5000/api
export MIJIA_TOKEN=replace-with-local-jwt-access-token
export MCP_TRANSPORT=stdio
```

Windows PowerShell:

```powershell
$env:MIJIA_API_URL = "http://127.0.0.1:5000/api"
$env:MIJIA_TOKEN = "replace-with-local-jwt-access-token"
$env:MCP_TRANSPORT = "stdio"
```

## Install The Plugin In Codex

If using this repository as a repo-local marketplace:

```bash
codex plugin marketplace add .
codex plugin add mijia-control-codex@personal
```

Start a new Codex thread after installation so the skill and MCP server are loaded.

## First Check

Ask Codex:

```text
List my Mijia devices through mijia-control.
```

Codex should use the `mijia-control` MCP server or upstream CLI. If it cannot start MCP, check `docs/TROUBLESHOOTING.md`.

## Runtime Check

On Windows, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\mijia-control-codex\scripts\check-runtime.ps1
```

This reports whether Git, Python, upstream `mijia-control` imports, the CLI or default venv CLI, the effective API URL, a `MIJIA_TOKEN` or CLI token file, and API reachability are ready.

If it reports missing Python or missing upstream modules, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\mijia-control-codex\scripts\setup-windows.ps1 -InstallPythonWithWinget
```

If it reports missing token, log in with `mijia-control login`, then either rely on the CLI token file or set `MIJIA_TOKEN` in the environment that launches Codex. If it reports API reachability failure, run `scripts\ensure_mijia_service.py` or use the optional MCP wrapper so Codex can autostart the local upstream service.
