# opencode-notify-marker

> Marker file plugin for OpenCode - create files when events occur.

A plugin for [OpenCode](https://github.com/sst/opencode) that creates marker files in `/workspace/tmp/opencode-notify-marker-files/` when specific events occur. Useful for external monitoring scripts to detect when the AI needs attention (e.g. when you are running OpenCode in a container and can't receive OS notifications).

**Note:** This project is a fork of [kdco-notify](https://github.com/kdcokenny/opencode-notify) by kdcokenny, repurposed to create marker files instead of desktop notifications.

## Why This Exists

You want to monitor OpenCode sessions from external tools (shell scripts, monitoring dashboards, etc.) but don't want to poll the API. This plugin solves that:

- **Event-driven** - External tools watch the marker files instead of polling
- **Simple** - Just check if a file exists in `/workspace/tmp/opencode-notify-marker-files/`
- **Lightweight** - No API calls, no network requests, just file system operations

## Installation

Clone this repo and copy its `src/` into your Opencode config directory: `.opencode/plugin/`

For example, in my container:

```bash
ln -s /workspace/projects/opencode-notify-marker/src /workspace/.opencode/plugins/opencode-notify-marker
```

## How It Works

| Event             | Marker File           | Why                               |
| ----------------- | --------------------- | --------------------------------- |
| Session idle      | `SESSION_IDLE`        | Main task done - time to review   |
| Session error     | `SESSION_ERROR`       | Something broke - needs attention |
| Permission needed | `PERMISSION_UPDATED`  | AI is blocked, waiting for you    |
| Question asked    | `TOOL_EXECUTE_BEFORE` | AI needs your input               |

The plugin automatically:

1. Creates marker files in `/workspace/tmp/opencode-notify-marker-files/`
2. Only creates markers for parent sessions (not every sub-task)
3. Overwrites existing markers with new timestamps

## Configuration (Optional)

Works out of the box. To customize, create `~/.config/opencode/kdco-notifier-marker.json`:

```json
{
  "notifyChildSessions": false
}
```

## Example Usage

### Shell Script Monitoring

```bash
#!/bin/bash

# Customize marker directory with MARKER_DIR environment variable
MARKER_DIR="${MARKER_DIR:-/workspace/tmp/opencode-notify-marker-files}"

while true; do
  if [ -f "$MARKER_DIR/SESSION_IDLE" ]; then
    echo "Session complete! Checking output..."
    # Your logic here
    rm "$MARKER_DIR/SESSION_IDLE"
  fi

  if [ -f "$MARKER_DIR/SESSION_ERROR" ]; then
    echo "Session error detected!"
    # Your logic here
    rm "$MARKER_DIR/SESSION_ERROR"
  fi

  sleep 5
done
```

### Python Monitoring

```python
import os
import time
from pathlib import Path

MARKER_DIR = Path("/workspace/tmp/opencode-notify-marker-files")

while True:
    for marker in ["SESSION_IDLE", "SESSION_ERROR", "PERMISSION_UPDATED"]:
        marker_path = MARKER_DIR / marker
        if marker_path.exists():
            print(f"Event detected: {marker}")
            marker_path.unlink()

    time.sleep(5)
```

## Marker File Format

Each marker file contains a JSON object with a timestamp:

```json
{
  "created": "2024-01-15T10:30:45.123Z"
}
```

## Supported Events

| Event              | Event Type                       | Marker File           |
| ------------------ | -------------------------------- | --------------------- |
| Session idle       | `session.idle`                   | `SESSION_IDLE`        |
| Session error      | `session.error`                  | `SESSION_ERROR`       |
| Permission updated | `permission.updated`             | `PERMISSION_UPDATED`  |
| Question tool      | `tool.execute.before` (question) | `TOOL_EXECUTE_BEFORE` |

## Running the Watcher Script (Host)

If you're running OpenCode in a container but want desktop notifications on your host machine:

1. Copy `watch-for-marker-files.sh` to your host machine
2. Run it from the host (not the container):

```bash
./watch-for-marker-files.sh
```

The script watches the marker directory and sends desktop notifications when files are created. It automatically deletes the marker file after showing the notification.

**Customizing the marker directory:** Set the `WATCH_DIR` environment variable to watch a different directory:

```bash
WATCH_DIR="/custom/path" ./watch-for-marker-files.sh
```

**Note about directory configuration:**
- The **plugin** creates marker files in `MARKER_DIR` (default: `/workspace/tmp/opencode-notify-marker-files`)
- The **watcher script** monitors `WATCH_DIR` (default: `../../tmp/opencode-notify-marker-files` relative to the script)
- Both must point to the same directory for the watcher to detect the plugin's markers
- Configure `MARKER_DIR` in the plugin via `~/.config/opencode/opencode-notify-marker.json`
- Configure `WATCH_DIR` via environment variable when running the watcher script

**Note:** The script uses `notify-send` which is available on Linux. On macOS, you may need to install `terminal-notifier` or use a different notification method.

## License

MIT License

Copyright (c) 2026 arcanemachine

This project is a fork of [kdco-notify](https://github.com/kdcokenny/opencode-notify) by kdcokenny, repurposed to create marker files instead of desktop notifications.
