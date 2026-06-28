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
cd plugins\mijia-control-codex
powershell -ExecutionPolicy Bypass -File .\scripts\setup-windows.ps1
```

This installs upstream `mijia-control` into `%USERPROFILE%\mijia-control\venv` and prints the venv Python path to use if Codex cannot find `python`.

Start the upstream web service and complete upstream account/device setup:

```bash
python run.py
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

The `python` command must resolve to an environment where upstream `mijia-control` is installed. `env_vars` asks Codex to forward local `MIJIA_API_URL` and `MIJIA_TOKEN` into the stdio server process. If Codex cannot import `mcp_server`, install upstream into the Python environment Codex can see, or change the command to your venv Python in a local copy of the MCP config.

Important: `codex plugin list` showing `mijia-control-codex@personal installed, enabled` only confirms that Codex installed this plugin. It does not install Python, upstream `mijia-control`, or your local Xiaomi/Mijia credentials. Run this on Windows to see what is missing:

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\mijia-control-codex\scripts\check-runtime.ps1
```

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

Version `0.1.1` adds Windows runtime diagnostics for machines where the Codex plugin is installed but Python or upstream `mijia-control` is missing.

## License

This plugin is MIT licensed, matching the upstream `mijia-control` repository `LICENSE` file observed during development. This plugin does not vendor upstream source code.

## Privacy

No account, token, device ID, home ID, scene ID, QR code, IP address beyond localhost examples, or family information is included in this plugin. Users provide credentials and device configuration locally.
