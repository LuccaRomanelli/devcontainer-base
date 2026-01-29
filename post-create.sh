#!/bin/bash
set -e

echo "==> Setting up development environment..."

# Cleanup function for error handling
cleanup_on_failure() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo ""
        echo "=========================================="
        echo "  ERROR: Setup failed with exit code $exit_code"
        echo "=========================================="
        echo ""
        echo "Check the logs above for details."
    fi
    exit $exit_code
}
trap cleanup_on_failure EXIT

# Wait for network connectivity
wait_for_network() {
    local max_attempts=10
    local attempt=1
    echo "==> Checking network connectivity..."
    while [ $attempt -le $max_attempts ]; do
        if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
            echo "    Network is available."
            return 0
        fi
        echo "    Waiting for network... (attempt $attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    echo "    WARNING: Network check failed after $max_attempts attempts. Continuing anyway..."
    return 0
}

wait_for_network

# Load .env file if it exists
if [ -f ".env" ]; then
    echo "==> Loading user configuration from .env..."
    set -a
    source .env
    set +a
fi

# Homebrew setup with verification
if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
else
    echo "ERROR: Homebrew not found at /home/linuxbrew/.linuxbrew/bin/brew"
    echo "The container may not have been built correctly."
    exit 1
fi

# Mise setup with verification and fallback
if command -v mise &>/dev/null; then
    if [ -f "mise.toml" ] && [ "${MISE_AUTO_TRUST:-true}" = "true" ]; then
        echo "==> Trusting mise.toml..."
        mise trust
    fi
    eval "$(mise activate bash)"
else
    echo "WARNING: mise not found. Attempting to install via Homebrew..."
    if brew install mise; then
        eval "$(mise activate bash)"
    else
        echo "ERROR: Failed to install mise."
        exit 1
    fi
fi

# Git configuration (if provided via env vars)
if [ -n "$GIT_USER_NAME" ]; then
    echo "==> Configuring git user.name..."
    git config --global user.name "$GIT_USER_NAME"
fi
if [ -n "$GIT_USER_EMAIL" ]; then
    echo "==> Configuring git user.email..."
    git config --global user.email "$GIT_USER_EMAIL"
fi

# Dotfiles
DOTFILES_REPO="${DOTFILES_REPO:-}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
DOTFILES_STOW_EXCLUDE="${DOTFILES_STOW_EXCLUDE:-ghostty,waybar}"
DOTFILES_DIR="$HOME/.dotfiles"

if [ -n "$DOTFILES_REPO" ]; then
    if [ ! -d "$DOTFILES_DIR" ]; then
        echo "==> Cloning dotfiles from $DOTFILES_REPO (branch: $DOTFILES_BRANCH)..."
        git clone --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR"
    else
        echo "==> Updating dotfiles..."
        cd "$DOTFILES_DIR" && git pull && cd -
    fi

    # Apply dotfiles with stow
    echo "==> Applying dotfiles..."
    cd "$DOTFILES_DIR"
    rm -f "$HOME/.zshrc" 2>/dev/null || true

    # Convert exclude list to array
    IFS=',' read -ra EXCLUDE_PACKAGES <<< "$DOTFILES_STOW_EXCLUDE"

    for package in */; do
        package_name="${package%/}"

        # Skip hidden, README, and excluded packages
        skip=false
        [[ "$package_name" == .* ]] && skip=true
        [[ "$package_name" == "README"* ]] && skip=true

        for excluded in "${EXCLUDE_PACKAGES[@]}"; do
            [[ "$package_name" == "$excluded" ]] && skip=true
        done

        if [ "$skip" = false ]; then
            echo "    Stowing $package_name..."
            stow -v --restow "$package_name" 2>/dev/null || echo "    Warning: Could not stow $package_name"
        fi
    done
    cd -

    # Ensure brew and mise are in .zshrc after applying dotfiles
    echo "==> Ensuring brew and mise are configured in .zshrc..."
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q 'brew shellenv' "$HOME/.zshrc"; then
            echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.zshrc"
        fi
        if ! grep -q 'mise activate zsh' "$HOME/.zshrc"; then
            echo 'eval "$(mise activate zsh)"' >> "$HOME/.zshrc"
        fi
    fi
else
    echo "==> Skipping dotfiles (DOTFILES_REPO not set)"
fi

# Plugins do tmux
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "==> Installing tmux plugins..."
    ~/.tmux/plugins/tpm/bin/install_plugins || true
fi

# Project-specific dependencies (if exists)
if [ -f "project-dependencies.sh" ]; then
    echo "==> Running project-specific setup..."
    source project-dependencies.sh
fi

# Default shell configuration
DEFAULT_SHELL="${DEFAULT_SHELL:-zsh}"
if [ "$DEFAULT_SHELL" = "zsh" ] && [ -f /home/linuxbrew/.linuxbrew/bin/zsh ]; then
    sudo chsh -s /home/linuxbrew/.linuxbrew/bin/zsh dev 2>/dev/null || true
elif [ "$DEFAULT_SHELL" = "bash" ]; then
    sudo chsh -s /bin/bash dev 2>/dev/null || true
fi

# Clear trap on successful completion
trap - EXIT

echo ""
echo "=========================================="
echo "  Development environment ready!"
echo "=========================================="
echo ""
echo "Available tools:"
echo "  claude          - Claude Code CLI"
echo "  yazi            - Terminal file manager"
echo "  tmux            - Terminal multiplexer"
echo "  lazygit         - Git TUI"
echo "  mise            - Runtime version manager"
echo ""
