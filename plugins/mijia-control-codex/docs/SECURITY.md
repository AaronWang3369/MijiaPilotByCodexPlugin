# Security

This plugin can enable physical smart-home changes through upstream `mijia-control`. Treat it as a privileged local automation component.

## Rules

- Keep `MIJIA_TOKEN` local.
- Do not commit Xiaomi account credentials.
- Do not publish real device IDs, home IDs, scene IDs, room names, or camera data.
- Use read-only discovery before any device-changing action.
- Confirm device-changing actions in concrete terms before executing them.
- Prefer least privilege for the local user running Codex and upstream `mijia-control`.
- Rotate local tokens if they appear in logs, screenshots, chat, or git history.

## No Bypass Policy

This plugin intentionally forbids direct Xiaomi/Mijia access outside upstream `mijia-control`. Codex must not use:

- direct Xiaomi Cloud APIs;
- private Mi Home APIs;
- raw local device protocols;
- mobile app automation;
- browser automation into Xiaomi/Mijia web properties;
- direct BLE control libraries;
- HomeKit as a device-control bypass.

All device-facing operations must pass through upstream `mijia-control`.

## Reporting Issues

For plugin packaging or Codex integration issues, report them to the plugin repository.

For upstream device support, API behavior, CLI behavior, or MCP tool behavior, report them to:

```text
https://github.com/handsomejustin/mijia-control/issues
```
