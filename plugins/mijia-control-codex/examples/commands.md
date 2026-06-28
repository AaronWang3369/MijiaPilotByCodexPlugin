# Command Examples

All examples are intentionally generic. Replace placeholders only with values discovered from your own local `mijia-control` installation.

## Read-Only

```bash
mijia-control --help
mijia-control whoami
mijia-control xiaomi status
mijia-control home list
mijia-control device list
mijia-control device list --refresh
mijia-control device show <did>
mijia-control device get <did> <prop_name>
mijia-control scene list
```

## Device-Changing

Use only after confirming the target device and property/action from `mijia-control device show <did>`.

```bash
mijia-control device set <did> <prop_name> <value>
mijia-control device action <did> <action_name>
mijia-control scene run <scene_id>
```

## MCP

```bash
export MIJIA_API_URL=http://127.0.0.1:5000/api
export MIJIA_TOKEN=replace-with-local-jwt-access-token
export MCP_TRANSPORT=stdio
python -m mcp_server
```

Windows PowerShell:

```powershell
$env:MIJIA_API_URL = "http://127.0.0.1:5000/api"
$env:MIJIA_TOKEN = "replace-with-local-jwt-access-token"
$env:MCP_TRANSPORT = "stdio"
python -m mcp_server
```
