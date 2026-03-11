
# Claude Code CLI (claude-code)

Installs the Claude Code CLI globally using the native installer

## Example Usage

```json
"features": {
    "ghcr.io/Saissaken/anthropic-devcontainer-features/claude-code:2": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| shareSession | Symlinks ~/.claude to /claude-host-config. Requires a bind mount in devcontainer.json. | boolean | false |

## Customizations

### VS Code Extensions

- `anthropic.claude-code`

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
        "source=${localEnv:HOME}/.claude,target=/claude-host-config,type=bind"
    ]
}
```

When the container starts, `~/.claude` will be symlinked to the mounted host config directory. This shares authentication tokens and settings from your host machine.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/Saissaken/anthropic-devcontainer-features/blob/main/src/claude-code/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
