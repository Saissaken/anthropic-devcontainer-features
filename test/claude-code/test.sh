#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature-specific tests
check "claude cli installed" command -v claude
check "claude at /usr/local/bin" test -f /usr/local/bin/claude
check "claude version" claude --version
check "setup-claude-session script exists" test -f /usr/local/bin/setup-claude-session

# Report results
reportResults
