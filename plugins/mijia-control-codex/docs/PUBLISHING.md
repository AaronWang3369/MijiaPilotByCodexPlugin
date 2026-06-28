# Publishing

## Package Contents

Publish the full plugin directory:

```text
plugins/mijia-control-codex/
```

Required files:

- `.codex-plugin/plugin.json`
- `.mcp.json`
- `skills/mijia-control/SKILL.md`
- `README.md`
- `LICENSE`
- `docs/`
- `examples/`
- `config/mijia-control.env.example`
- `scripts/verify-plugin.mjs`

## Marketplace Entry

Example repo-local marketplace entry:

```json
{
  "name": "mijia-control-codex",
  "source": {
    "source": "local",
    "path": "./plugins/mijia-control-codex"
  },
  "policy": {
    "installation": "AVAILABLE",
    "authentication": "ON_INSTALL"
  },
  "category": "Productivity"
}
```

The repository also includes:

```text
.agents/plugins/marketplace.json
```

## Release Checklist

- Run `node scripts/verify-plugin.mjs` from the plugin root.
- Run the Codex plugin validator if available.
- Confirm no real secrets or device identifiers are present.
- Confirm README install steps match the published upstream `mijia-control` state.
- Confirm `.mcp.json` starts `python -m mcp_server` and does not include real env values.
- Confirm docs state that real-device verification requires a user-owned Xiaomi account and devices.

## License Note

This plugin is MIT licensed, matching the upstream `mijia-control` repository `LICENSE` file observed during development. It does not vendor upstream code. If a future release bundles or modifies upstream source, re-check upstream licensing before publishing.
