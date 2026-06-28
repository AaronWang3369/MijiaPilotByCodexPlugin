# Mijia Control Codex Plugin

Codex plugin for operating Xiaomi, Mijia, and Mi Home smart-home devices through the upstream [`handsomejustin/mijia-control`](https://github.com/handsomejustin/mijia-control) project only.

This plugin does not implement its own Xiaomi Cloud client, LAN protocol client, HomeKit bridge, or BLE device control. It gives Codex a dedicated skill, MCP startup configuration, and operating rules so smart-home actions are routed through `mijia-control`.

## What This Plugin Contains

- `.codex-plugin/plugin.json`: Codex plugin manifest.
- `.mcp.json`: Codex MCP server wiring for the upstream `mcp_server` package.
- `skills/mijia-control/SKILL.md`: required Codex behavior for Xiaomi/Mijia work.
- `config/mijia-control.env.example`: environment variable template.
- `docs/`: installation, setup, verification, troubleshooting, security, privacy, and publishing notes.
- `examples/`: sample commands and conversations.
- `scripts/verify-plugin.mjs`: local structure and privacy validation.
- `scripts/ensure_mijia_service.py`: local helper that checks and starts the upstream `mijia-control` Flask service.
- `scripts/mijia-mcp-wrapper.py`: optional local MCP wrapper that starts the upstream service if needed, starts upstream MCP, and reuses the local CLI token file when `MIJIA_TOKEN` is not set.
- `scripts/check-runtime.ps1` and `scripts/setup-windows.ps1`: Windows diagnostics and upstream runtime setup helpers.

## Upstream Facts Verified

The plugin was built after checking `handsomejustin/mijia-control` at commit `bb5ec6e605c0e452bafd60c4ffe9147e785a1bf2` dated `2026-05-24`.

Observed upstream structure:

- Flask application with REST APIs under `app/api/`.
- CLI entry file: `mijia_cli.py`.
- MCP server package: `mcp_server/`.
- Config module: `config/__init__.py`.
- Python package metadata: `pyproject.toml`.
- Environment template: `.env.example`.

Observed upstream launch and integration points:

- Web service: `python run.py`.
- CLI: `mijia-control`.
- MCP module: `python -m mcp_server`.
- Console scripts in `pyproject.toml`: `mijia-control` and `mijia-mcp`.
- MCP default transport: `stdio`, configurable with `MCP_TRANSPORT`.
- API base env var: `MIJIA_API_URL`, defaulting upstream to `http://127.0.0.1:5000/api`.
- token env var: `MIJIA_TOKEN`.

Observed MCP tools:

`list_devices`, `get_device`, `get_property`, `set_property`, `run_action`, `list_scenes`, `run_scene`, `list_homes`, `get_home`, `list_ble_devices`, `get_ble_sensor`, `get_ble_readings`.

## Install

Install the upstream project first:

```bash
git clone https://github.com/handsomejustin/mijia-control.git
cd mijia-control
python -m venv venv
source venv/bin/activate
pip install -e ".[mcp]"
```

On Windows PowerShell:

```powershell
git clone https://github.com/handsomejustin/mijia-control.git
cd mijia-control
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -e ".[mcp]"
```

Or use the plugin helper on Windows:

```powershell
cd path\to\MijiaPilotByCodexPlugin
powershell -ExecutionPolicy Bypass -File .\plugins\mijia-control-codex\scripts\setup-windows.ps1 -InstallPythonWithWinget
```

This installs Python 3.12 with `winget` when Python is missing, clones upstream `mijia-control` into `%USERPROFILE%\mijia-control`, creates `%USERPROFILE%\mijia-control\venv`, installs `.[mcp]`, verifies imports, and prints the venv Python path to use if Codex cannot find `python`.

Complete upstream account/device setup. You can start the upstream web service manually:

```bash
python run.py
```

Or let the plugin helper start the local upstream service when Codex first needs it:

```bash
python scripts/ensure_mijia_service.py
```

Then log in to the upstream service and obtain a local token:

```bash
mijia-control login
```

If you prefer direct env setup, use the template:

```bash
cp config/mijia-control.env.example .env.local
```

Do not commit `.env.local` or any file containing `MIJIA_TOKEN`, Xiaomi credentials, device IDs, home IDs, scene IDs, QR payloads, or family information.

## Install In Codex

For a repo-local marketplace, use the example marketplace at:

```text
.agents/plugins/marketplace.json
```

It points to:

```text
./plugins/mijia-control-codex
```

Install the marketplace root in Codex if you are using this repo-local marketplace:

```bash
codex plugin marketplace add .
codex plugin add mijia-control-codex@personal
```

For public distribution, publish the plugin directory and marketplace entry from this repository, then instruct users to install from the marketplace name you publish.

## Configure MCP

The plugin declares this MCP server in `.mcp.json`:

```json
{
  "mcpServers": {
    "mijia-control": {
      "type": "stdio",
      "command": "python",
      "args": ["-m", "mcp_server"],
      "env": {
        "MCP_TRANSPORT": "stdio"
      },
      "env_vars": ["MIJIA_API_URL", "MIJIA_TOKEN"]
    }
  }
}
```

The `python` command must resolve to an environment where upstream `mijia-control` is installed. `env_vars` asks Codex to forward local `MIJIA_API_URL` and `MIJIA_TOKEN` into the stdio server process. If Codex cannot import `mcp_server`, install upstream into the Python environment Codex can see, or configure a machine-local MCP command that uses your venv Python.

On Windows, the helper also prints a local MCP override using `scripts/mijia-mcp-wrapper.py`. That wrapper is optional. It first ensures the local upstream Flask service is reachable, then starts upstream `mcp_server`. It can also reuse the token file written by `mijia-control login` at `~/.config/mijia-control/token.json` when `MIJIA_TOKEN` is not set.

Service autostart is controlled by:

```bash
MIJIA_CONTROL_DIR=/path/to/mijia-control
MIJIA_CONTROL_PYTHON=/path/to/mijia-control/venv/bin/python
MIJIA_CONTROL_AUTOSTART=0
```

`MIJIA_CONTROL_AUTOSTART=0` disables automatic startup. The helper only starts a local service when `MIJIA_API_URL` points to localhost.

Important: `codex plugin list` showing `mijia-control-codex@personal installed, enabled` only confirms that Codex installed this plugin. It does not install Python, upstream `mijia-control`, or your local Xiaomi/Mijia credentials. Run this on Windows to see what is missing:

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\mijia-control-codex\scripts\check-runtime.ps1
```

If the output reports missing Python or missing upstream modules, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\mijia-control-codex\scripts\setup-windows.ps1 -InstallPythonWithWinget
```

Then run `check-runtime.ps1` again. A plugin can be installed and enabled while device listing still fails if no CLI token or `MIJIA_TOKEN` exists, no local upstream checkout can be found for autostart, or no Xiaomi account/devices have been bound in upstream `mijia-control`.

## Use

Ask Codex for Mijia work directly:

- `List my Mijia devices through mijia-control.`
- `Check whether the bedroom light is online.`
- `Run the Welcome Home scene through mijia-control.`

Codex should use the plugin skill and MCP tools, or the upstream CLI, and should not bypass `mijia-control`.

## Safety Rule

For Xiaomi, Mijia, Mi Home, and Xiaomi smart-home devices, Codex must not call Xiaomi Cloud, private Mi Home APIs, local device protocols, HomeKit, BLE libraries, browser sessions, or mobile apps directly. All device-facing operations must go through the upstream `mijia-control` CLI or MCP server.

## Verify

Run the plugin-local checks:

```bash
node scripts/verify-plugin.mjs
```

If Python dependencies are available, also run the Codex plugin validator from the plugin-creator skill:

```bash
python path/to/plugin-creator/scripts/validate_plugin.py path/to/plugins/mijia-control-codex
```

In this repository, the verification script checks:

- manifest JSON shape and required fields;
- `.mcp.json` server declaration;
- Skill frontmatter and routing rule text;
- config template avoids real secrets;
- no obvious private token/device/home placeholders are committed;
- marketplace entry points to the plugin directory.

During local development, the upstream project was also installed into a temporary virtual environment with `pip install -e ".[mcp]"`. `mijia-control --help`, Python imports for `mcp_server` and `mijia_cli`, and an MCP stdio `initialize` plus `list_tools` session were verified. The MCP session returned 12 tools matching the upstream source.

Version `0.1.4` adds local upstream service autostart through `scripts/ensure_mijia_service.py` and updates the optional MCP wrapper so Codex can bring up the upstream Flask service before using MCP.

## License

This plugin is MIT licensed, matching the upstream `mijia-control` repository `LICENSE` file observed during development. This plugin does not vendor upstream source code.

## Privacy

No account, token, device ID, home ID, scene ID, QR code, IP address beyond localhost examples, or family information is included in this plugin. Users provide credentials and device configuration locally.
