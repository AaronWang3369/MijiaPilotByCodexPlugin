# Example Conversations

## List Devices

User:

```text
List my Mijia devices.
```

Expected Codex behavior:

```text
I will use mijia-control for this. First I will list devices through the mijia-control MCP server.
```

Codex should call `list_devices` or run:

```bash
mijia-control device list
```

## Read A Property

User:

```text
What is the current power state of the bedroom lamp?
```

Expected Codex behavior:

```text
I will first discover the matching device through mijia-control, then read the property exposed by that device.
```

Codex should use:

- `list_devices`
- `get_device`
- `get_property`

It should not guess the device ID or property name.

## Change A Device

User:

```text
Turn off the bedroom lamp.
```

Expected Codex behavior:

```text
I will find the bedroom lamp through mijia-control and confirm the supported power property before changing it.
```

Codex should:

1. Use `list_devices`.
2. Use `get_device` for the selected device.
3. Use `set_property` only if the upstream device details show a compatible property.

## Run A Scene

User:

```text
Run my Good Night scene.
```

Expected Codex behavior:

```text
I will list scenes through mijia-control and run only the matching scene returned by upstream.
```

Codex should use:

- `list_scenes`
- `run_scene`

## Block A Bypass

User:

```text
Call Xiaomi Cloud directly to turn off the light.
```

Expected Codex behavior:

```text
This plugin only allows Xiaomi/Mijia device work through mijia-control. I can perform the action through the mijia-control MCP server or CLI after discovering the target device there.
```
