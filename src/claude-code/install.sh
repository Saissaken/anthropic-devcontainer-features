#!/bin/sh
set -eu

SHARE_SESSION="${SHARESESSION:-false}"

# Function to detect the package manager
detect_package_manager() {
    for pm in apt-get apk dnf yum; do
        if command -v $pm >/dev/null; then
            case $pm in
                apt-get) echo "apt" ;;
                *) echo "$pm" ;;
            esac
            return 0
        fi
    done
    echo "unknown"
    return 1
}

# Function to install packages using the appropriate package manager
install_packages() {
    local pkg_manager="$1"
    shift
    local packages="$@"

    case "$pkg_manager" in
        apt)
            apt-get update
            apt-get install -y $packages
            ;;
        apk)
            apk add --no-cache $packages
            ;;
        dnf|yum)
            $pkg_manager install -y $packages
            ;;
        *)
            echo "WARNING: Unsupported package manager. Cannot install packages: $packages"
            return 1
            ;;
    esac

    return 0
}

# Main script starts here
main() {
    echo "Activating feature 'claude-code'"

    # Detect package manager
    PKG_MANAGER=$(detect_package_manager)
    echo "Detected package manager: $PKG_MANAGER"

    # Ensure curl and bash are available
    if ! command -v curl >/dev/null || ! command -v bash >/dev/null; then
        echo "Installing curl and bash..."
        install_packages "$PKG_MANAGER" curl bash
    fi

    # Install Alpine-specific dependencies
    if [ "$PKG_MANAGER" = "apk" ]; then
        echo "Installing Alpine-specific dependencies..."
        install_packages apk libgcc libstdc++ ripgrep
    fi

    # Install Claude Code using the native installer (with retry for rate limits)
    echo "Installing Claude Code via native installer..."
    MAX_RETRIES=5
    RETRY_DELAY=5
    for i in $(seq 1 $MAX_RETRIES); do
        echo "Attempt $i of $MAX_RETRIES..."
        if curl -fsSL https://claude.ai/install.sh | bash; then
            break
        fi
        if [ "$i" = "$MAX_RETRIES" ]; then
            echo "ERROR: Native installer failed after $MAX_RETRIES attempts"
            exit 1
        fi
        echo "Installer failed, retrying in ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
        RETRY_DELAY=$((RETRY_DELAY * 2))
    done

    # Copy the binary to /usr/local/bin for multi-user access
    if [ -f "$HOME/.local/bin/claude" ]; then
        cp "$(readlink -f "$HOME/.local/bin/claude")" /usr/local/bin/claude
        chmod 755 /usr/local/bin/claude
    else
        echo "ERROR: Claude binary not found at ~/.local/bin/claude after installation"
        exit 1
    fi

    # Verify installation
    if command -v claude >/dev/null; then
        echo "Claude Code CLI installed successfully!"
        claude --version
    else
        echo "ERROR: Claude Code CLI installation failed!"
        exit 1
    fi

    # Generate the session setup helper script
    cat > /usr/local/bin/setup-claude-session << 'SCRIPT'
#!/bin/sh
SHARE_SESSION="__SHARE_SESSION__"

if [ "$SHARE_SESSION" != "true" ]; then
    exit 0
fi

# Detect current user's home directory
CURRENT_USER=$(whoami)
USER_HOME=$(getent passwd "$CURRENT_USER" | cut -d: -f6)

if [ -z "$USER_HOME" ]; then
    USER_HOME="$HOME"
fi

MOUNT_PATH="/claude-host-config"

if [ -d "$MOUNT_PATH" ]; then
    # Remove existing ~/.claude if it exists (file, dir, or symlink)
    if [ -e "$USER_HOME/.claude" ] || [ -L "$USER_HOME/.claude" ]; then
        rm -rf "$USER_HOME/.claude"
    fi
    ln -s "$MOUNT_PATH" "$USER_HOME/.claude"
    echo "Claude session shared: $USER_HOME/.claude -> $MOUNT_PATH"
else
    echo "WARNING: shareSession is enabled but $MOUNT_PATH is not mounted."
    echo "Add the following mounts to your devcontainer.json:"
    echo ""
    echo '  "mounts": ['
    echo '    "source=${localEnv:HOME}/.claude,target=/claude-host-config,type=bind",'
    echo '    "source=${localEnv:HOME}/.claude.json,target=/claude-host-credentials,type=bind"'
    echo '  ]'
    echo ""
fi

CREDENTIALS_PATH="/claude-host-credentials"
if [ -f "$CREDENTIALS_PATH" ]; then
    if [ -e "$USER_HOME/.claude.json" ] || [ -L "$USER_HOME/.claude.json" ]; then
        rm -f "$USER_HOME/.claude.json"
    fi
    ln -s "$CREDENTIALS_PATH" "$USER_HOME/.claude.json"
    echo "Claude credentials shared: $USER_HOME/.claude.json -> $CREDENTIALS_PATH"
fi
SCRIPT

    # Inject the SHARE_SESSION value
    sed -i "s|__SHARE_SESSION__|${SHARE_SESSION}|g" /usr/local/bin/setup-claude-session
    chmod 755 /usr/local/bin/setup-claude-session
}

# Execute main function
main
