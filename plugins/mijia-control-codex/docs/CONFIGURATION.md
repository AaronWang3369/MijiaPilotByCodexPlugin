# Configuration

## Plugin Configuration

The plugin itself stores no credentials. It ships only a template:

```text
config/mijia-control.env.example
```

Required runtime variables:

```bash
MIJIA_API_URL=http://127.0.0.1:5000/api
MIJIA_TOKEN=replace-with-local-jwt-access-token
MCP_TRANSPORT=stdio
```

## MCP Configuration

The plugin `.mcp.json` starts upstream `mcp_server` with:

```bash
python -m mcp_server
```

It sets `MCP_TRANSPORT=stdio` and uses Codex MCP `env_vars` to forward `MIJIA_API_URL` and `MIJIA_TOKEN` from the local environment. This requires that the `python` command used by Codex can import the upstream `mcp_server` package. The most reliable setup is:

1. Clone upstream `mijia-control`.
2. Create a venv.
3. Install upstream with `pip install -e ".[mcp]"`.
4. Launch Codex from an environment where that venv or Python installation is visible, or adapt `.mcp.json` locally to the venv Python path.

If the target machine has no `python` on PATH, use the venv Python path printed by `scripts/setup-windows.ps1` and change the local MCP command from:

```json
"command": "python"
```

to a machine-local absolute path such as:

```json
"command": "C:\\Users\\Administrator\\mijia-control\\venv\\Scripts\\python.exe"
```

Do not commit machine-local paths to the public plugin repository.

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
