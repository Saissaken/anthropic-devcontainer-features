# Using Claude Code in devcontainers

## How it works

This feature installs Claude Code using the [native installer](https://claude.ai/install.sh), which does not require Node.js. The binary is placed at `/usr/local/bin/claude` for multi-user access.

## Basic usage

```json
"features": {
    "ghcr.io/anthropics/devcontainer-features/claude-code:2": {}
}
```

## Sharing your host session

To avoid re-authenticating inside the devcontainer, you can share your host machine's Claude session by enabling `shareSession` and adding a bind mount:

```json
{
    "features": {
        "ghcr.io/anthropics/devcontainer-features/claude-code:2": {
            "shareSession": true
        }
    },
    "mounts": [
        "source=${localEnv:HOME}/.claude,target=/claude-host-config,type=bind",
        "source=${localEnv:HOME}/.claude.json,target=/claude-host-credentials,type=bind"
    ]
}
```

When the container starts, `~/.claude` and `~/.claude.json` will be symlinked to the mounted host paths. This shares authentication credentials and settings from your host machine.
