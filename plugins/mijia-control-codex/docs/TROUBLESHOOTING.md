# Troubleshooting

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
