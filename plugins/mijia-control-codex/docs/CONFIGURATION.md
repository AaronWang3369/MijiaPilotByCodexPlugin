# Configuration

## Plugin Configuration

The plugin itself stores no credentials. It ships only a template:

```text
config/mijia-control.env.example
```

Runtime variables:

```bash
MIJIA_API_URL=http://127.0.0.1:5000/api
MIJIA_TOKEN=replace-with-local-jwt-access-token
MCP_TRANSPORT=stdio
MIJIA_CONTROL_DIR=/path/to/mijia-control
MIJIA_CONTROL_PYTHON=/path/to/mijia-control/venv/bin/python
MIJIA_CONTROL_AUTOSTART=1
```

`MIJIA_API_URL` defaults upstream to `http://127.0.0.1:5000/api`. `MIJIA_TOKEN` can be provided as an environment variable. On machines using the optional wrapper, the wrapper can reuse the token file created by `mijia-control login` and can start the local upstream web service.

## MCP Configuration

The plugin `.mcp.json` starts upstream `mcp_server` with:

```bash
python -m mcp_server
```

It sets `MCP_TRANSPORT=stdio` and uses Codex MCP `env_vars` to forward `MIJIA_API_URL` and `MIJIA_TOKEN` from the local environment when present. This requires that the `python` command used by Codex can import the upstream `mcp_server` package. The most reliable setup is:

1. Clone upstream `mijia-control`.
2. Create a venv.
3. Install upstream with `pip install -e ".[mcp]"`.
4. Launch Codex from an environment where that venv or Python installation is visible, or add a machine-local MCP command that uses the venv Python path.

If the target machine has no `python` on PATH, use the venv Python path printed by `scripts/setup-windows.ps1` and change the local MCP command from:

```json
"command": "python"
```

to a machine-local absolute path such as:

```json
"command": "C:\\Users\\Administrator\\mijia-control\\venv\\Scripts\\python.exe"
```

On machines where the Codex process cannot see the venv Python, or where you want MCP to reuse the token created by `mijia-control login` and autostart the local upstream service, add a local MCP server that uses the optional wrapper with an absolute plugin path:

```powershell
codex mcp add mijia-control --env MCP_TRANSPORT=stdio --env MIJIA_API_URL=http://127.0.0.1:5000/api -- C:\Users\you\mijia-control\venv\Scripts\python.exe C:\path\to\plugin\scripts\mijia-mcp-wrapper.py
```

Do not commit machine-local paths to the public plugin repository.

## Service Autostart Configuration

The plugin helper starts only the local upstream Flask service. It does not call Xiaomi Cloud, enumerate devices, or change device state.

Run it directly when testing:

```bash
python scripts/ensure_mijia_service.py
```

Configuration:

- `MIJIA_CONTROL_DIR`: upstream checkout containing `run.py`.
- `MIJIA_CONTROL_PYTHON`: Python executable to use for `run.py`.
- `MIJIA_CONTROL_AUTOSTART`: set to `0`, `false`, `no`, or `off` to disable startup.
- `MIJIA_CONTROL_CODEX_STATE_DIR`: optional directory for service PID and log files.

The helper starts a service only for local API URLs such as `http://127.0.0.1:5000/api` or `http://localhost:5000/api`. For remote `MIJIA_API_URL` values, it only checks reachability.

## CLI Configuration

The upstream CLI reads:

- `MIJIA_API_URL`, defaulting to `http://127.0.0.1:5000/api`.
- `MIJIA_TOKEN`, if set.
- Otherwise `~/.config/mijia-control/token.json`, created by `mijia-control login`.

Use these commands for read-only checks:

```bash
mijia-control whoami
mijia-control xiaomi status
mijia-control home list
mijia-control device list
mijia-control scene list
```

Use these commands only after confirming the target:

```bash
mijia-control device set <did> <prop_name> <value>
mijia-control device action <did> <action_name>
mijia-control scene run <scene_id>
```

## Data That Must Stay Local

Never commit or publish:

- Xiaomi account credentials.
- `MIJIA_TOKEN`.
- JWT refresh tokens.
- QR login payloads.
- real device IDs.
- real home IDs.
- real scene IDs.
- family names, room names, addresses, or camera stream data.
