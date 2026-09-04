
#!/usr/bin/env bash

set -e

# ============================================================
# AgentRouter + Claude Code / Codex Setup Script
# macOS / Linux
# ============================================================

clear

echo "============================================================"
echo "        AgentRouter CLI Setup"
echo "============================================================"
echo
echo "This script will:"
echo "  1. Install NVM"
echo "  2. Install Node.js 22"
echo "  3. Install Claude Code or Codex"
echo "  4. Configure AgentRouter"
echo
echo "============================================================"
echo

# ------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------

error_exit() {
    echo
    echo "============================================================"
    echo "ERROR: $1"
    echo "============================================================"
    echo
    exit 1
}

pause() {
    echo
    read -r -p "Press Enter to continue..."
}

# ------------------------------------------------------------
# Check operating system
# ------------------------------------------------------------

OS="$(uname -s)"

case "$OS" in
    Darwin)
        SHELL_CONFIG="$HOME/.zshrc"
        ;;
    Linux)
        if [ -f "$HOME/.bashrc" ]; then
            SHELL_CONFIG="$HOME/.bashrc"
        elif [ -f "$HOME/.zshrc" ]; then
            SHELL_CONFIG="$HOME/.zshrc"
        else
            SHELL_CONFIG="$HOME/.bashrc"
        fi
        ;;
    *)
        error_exit "This script supports macOS and Linux only."
        ;;
esac

# ------------------------------------------------------------
# Check curl
# ------------------------------------------------------------

if ! command -v curl >/dev/null 2>&1; then
    error_exit "curl is not installed. Please install curl and run this script again."
fi

# ------------------------------------------------------------
# Install NVM
# ------------------------------------------------------------

echo
echo "============================================================"
echo "Step 1: Installing NVM"
echo "============================================================"
echo

if [ -s "$HOME/.nvm/nvm.sh" ]; then
    echo "NVM appears to already be installed."
else
    echo "Installing NVM..."
    echo

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.6/install.sh | bash \
        || error_exit "NVM installation failed."

    echo
    echo "NVM installation completed."
fi

# ------------------------------------------------------------
# Load NVM into the current shell
# ------------------------------------------------------------

export NVM_DIR="$HOME/.nvm"

if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck disable=SC1090
    source "$NVM_DIR/nvm.sh"
else
    error_exit "NVM was installed, but nvm.sh could not be found."
fi

if ! command -v nvm >/dev/null 2>&1; then
    error_exit "NVM could not be loaded into the current shell."
fi

echo
echo "NVM version:"
nvm --version

# ------------------------------------------------------------
# Install Node.js 22
# ------------------------------------------------------------

echo
echo "============================================================"
echo "Step 2: Installing Node.js 22"
echo "============================================================"
echo

nvm install 22 || error_exit "Node.js 22 installation failed."

echo
echo "Switching to Node.js 22..."

nvm use 22 || error_exit "Could not switch to Node.js 22."

# Set Node 22 as the default for future shells.
nvm alias default 22 >/dev/null 2>&1 || true

# ------------------------------------------------------------
# Confirm Node/npm installation
# ------------------------------------------------------------

echo
echo "============================================================"
echo "Step 3: Confirming Node.js and npm"
echo "============================================================"
echo

NODE_VERSION="$(node -v)" || error_exit "Node.js is not available."
NPM_VERSION="$(npm -v)" || error_exit "npm is not available."

echo "Node.js: $NODE_VERSION"
echo "npm:     $NPM_VERSION"

echo

# ------------------------------------------------------------
# Select CLI
# ------------------------------------------------------------

echo "============================================================"
echo "Step 4: Choose your AI coding CLI"
echo "============================================================"
echo
echo "1) Claude Code"
echo "2) Codex"
echo

while true; do
    read -r -p "Enter your choice [1-2]: " CLI_CHOICE

    case "$CLI_CHOICE" in
        1)
            CLI="claude"
            break
            ;;
        2)
            CLI="codex"
            break
            ;;
        *)
            echo "Invalid choice. Please enter 1 or 2."
            ;;
    esac
done

# ------------------------------------------------------------
# Claude Code
# ------------------------------------------------------------

if [ "$CLI" = "claude" ]; then

    echo
    echo "============================================================"
    echo "Installing Claude Code"
    echo "============================================================"
    echo

    npm install -g @anthropic-ai/claude-code@latest \
        || error_exit "Claude Code installation failed."

    echo
    echo "Claude Code version:"
    claude --version || error_exit "Claude Code was installed but could not be executed."

    # --------------------------------------------------------
    # AgentRouter API key
    # --------------------------------------------------------

    echo
    echo "============================================================"
    echo "AgentRouter Configuration"
    echo "============================================================"
    echo
    echo "Paste your AgentRouter API key."
    echo "Spaces will automatically be removed."
    echo

    while true; do
        read -r -s -p "AgentRouter API key: " AGENTROUTER_KEY
        echo

        # Remove all whitespace.
        AGENTROUTER_KEY="$(printf '%s' "$AGENTROUTER_KEY" | tr -d '[:space:]')"

        if [ -n "$AGENTROUTER_KEY" ]; then
            break
        fi

        echo "The API key cannot be empty."
        echo
    done

    # --------------------------------------------------------
    # Select Claude model
    # --------------------------------------------------------

    echo
    echo "============================================================"
    echo "Select your Claude model"
    echo "============================================================"
    echo
    echo "1) claude-opus-4-6"
    echo "2) claude-opus-4-7"
    echo "3) claude-opus-4-8"
    echo "4) claude-opus-4-9"
    echo "5) claude-opus-5"
    echo

    while true; do
        read -r -p "Enter your choice [1-5]: " MODEL_CHOICE

        case "$MODEL_CHOICE" in
            1)
                ANTHROPIC_MODEL="claude-opus-4-6"
                break
                ;;
            2)
                ANTHROPIC_MODEL="claude-opus-4-7"
                break
                ;;
            3)
                ANTHROPIC_MODEL="claude-opus-4-8"
                break
                ;;
            4)
                ANTHROPIC_MODEL="claude-opus-4-9"
                break
                ;;
            5)
                ANTHROPIC_MODEL="claude-opus-5"
                break
                ;;
            *)
                echo "Invalid choice. Please enter a number from 1 to 5."
                ;;
        esac
    done

    # --------------------------------------------------------
    # Configure Claude Code environment variables
    # --------------------------------------------------------

    echo
    echo "Configuring Claude Code..."
    echo

    # Remove previously generated AgentRouter configuration
    # so running this script again does not create duplicates.
    if [ -f "$SHELL_CONFIG" ]; then
        TMP_CONFIG="$(mktemp)"

        awk '
        BEGIN { skip=0 }

        /^# >>> AgentRouter Claude Code Configuration >>>$/ {
            skip=1
            next
        }

        /^# <<< AgentRouter Claude Code Configuration <<<$ / {
            skip=0
            next
        }

        skip == 0 {
            print
        }
        ' "$SHELL_CONFIG" > "$TMP_CONFIG" 2>/dev/null || cp "$SHELL_CONFIG" "$TMP_CONFIG"

        mv "$TMP_CONFIG" "$SHELL_CONFIG"
    fi

    cat >> "$SHELL_CONFIG" <<EOF

# >>> AgentRouter Claude Code Configuration >>>
export ANTHROPIC_AUTH_TOKEN="$AGENTROUTER_KEY"
export ANTHROPIC_BASE_URL="https://agentrouter.org"
export ANTHROPIC_MODEL="$ANTHROPIC_MODEL"
# <<< AgentRouter Claude Code Configuration <<<
EOF

    # Apply the settings immediately to this shell.
    export ANTHROPIC_AUTH_TOKEN="$AGENTROUTER_KEY"
    export ANTHROPIC_BASE_URL="https://agentrouter.org"
    export ANTHROPIC_MODEL="$ANTHROPIC_MODEL"

    echo "Claude Code configuration completed."
    echo
    echo "ANTHROPIC_BASE_URL = $ANTHROPIC_BASE_URL"
    echo "ANTHROPIC_MODEL    = $ANTHROPIC_MODEL"
    echo "ANTHROPIC_AUTH_TOKEN has been configured."
fi

# ------------------------------------------------------------
# Codex
# ------------------------------------------------------------

if [ "$CLI" = "codex" ]; then

    echo
    echo "============================================================"
    echo "Installing Codex"
    echo "============================================================"
    echo

    npm install -g @openai/codex@latest \
        || error_exit "Codex installation failed."

    echo
    echo "Codex version:"
    codex --version || error_exit "Codex was installed but could not be executed."

    # --------------------------------------------------------
    # AgentRouter API key
    # --------------------------------------------------------

    echo
    echo "============================================================"
    echo "AgentRouter Configuration"
    echo "============================================================"
    echo
    echo "Paste your AgentRouter API key."
    echo "Spaces will automatically be removed."
    echo

    while true; do
        read -r -s -p "AgentRouter API key: " AGENTROUTER_KEY
        echo

        # Remove all whitespace.
        AGENTROUTER_KEY="$(printf '%s' "$AGENTROUTER_KEY" | tr -d '[:space:]')"

        if [ -n "$AGENTROUTER_KEY" ]; then
            break
        fi

        echo "The API key cannot be empty."
        echo
    done

    # --------------------------------------------------------
    # Create ~/.codex/config.toml
    # --------------------------------------------------------

    CODEX_DIR="$HOME/.codex"
    CODEX_CONFIG="$CODEX_DIR/config.toml"

    mkdir -p "$CODEX_DIR" \
        || error_exit "Could not create $CODEX_DIR."

    # If an existing config exists, make a backup before replacing it.
    if [ -f "$CODEX_CONFIG" ]; then
        BACKUP_FILE="$CODEX_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"

        cp "$CODEX_CONFIG" "$BACKUP_FILE" \
            || error_exit "Could not back up the existing Codex configuration."

        echo
        echo "Existing Codex configuration backed up to:"
        echo "$BACKUP_FILE"
    fi

    cat > "$CODEX_CONFIG" <<EOF
model = "gpt-5.6-sol"
model_provider = "agentrouter"

[model_providers.agentrouter]
name = "AgentRouter"
base_url = "https://agentrouter.org/v1"
wire_api = "responses"
requires_openai_auth = false
experimental_bearer_token = "$AGENTROUTER_KEY"
EOF

    echo
    echo "Codex configuration created:"
    echo "$CODEX_CONFIG"
fi

# ------------------------------------------------------------
# Final verification
# ------------------------------------------------------------

echo
echo "============================================================"
echo "                 SETUP COMPLETE"
echo "============================================================"
echo

echo "Node.js:"
node -v

echo
echo "npm:"
npm -v

echo

if [ "$CLI" = "claude" ]; then
    echo "Claude Code:"
    claude --version

    echo
    echo "AgentRouter model:"
    echo "$ANTHROPIC_MODEL"

    echo
    echo "Claude Code is configured to use:"
    echo "$ANTHROPIC_BASE_URL"

    echo
    echo "Configuration saved to:"
    echo "$SHELL_CONFIG"

elif [ "$CLI" = "codex" ]; then
    echo "Codex:"
    codex --version

    echo
    echo "Codex configuration:"
    echo "$CODEX_CONFIG"
fi

echo
echo "============================================================"
echo "Everything completed successfully."
echo "============================================================"
echo
echo "You may now use your selected CLI."
echo