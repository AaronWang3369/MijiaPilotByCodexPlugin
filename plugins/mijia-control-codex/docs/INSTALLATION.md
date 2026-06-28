# Installation

## Prerequisites

- Codex with plugin support.
- Python 3.10 or newer.
- A local clone or installation of `handsomejustin/mijia-control`.
- A running upstream `mijia-control` web service.
- A local JWT access token from the upstream service.

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
powershell -ExecutionPolicy Bypass -File .\plugins\mijia-control-codex\scripts\setup-windows.ps1
```

The helper clones upstream `mijia-control` to `%USERPROFILE%\mijia-control`, creates a venv, installs `.[mcp]`, verifies imports, and prints the venv Python path.

## Configure Upstream

Follow the upstream README to configure `.env`, initialize the database, start `python run.py`, register a local user, and bind a Xiaomi account.

The upstream project currently provides `.env.example` with settings such as:

- `FLASK_APP=app:create_app`
- `FLASK_ENV=development`
- `SECRET_KEY`
- `JWT_SECRET_KEY`
- `DATABASE_URL`
- `GO2RTC_URL`
- optional HomeKit and BLE settings

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

This reports whether Git, Python, upstream `mijia-control` imports, the CLI, `MIJIA_API_URL`, `MIJIA_TOKEN`, and API reachability are ready.
