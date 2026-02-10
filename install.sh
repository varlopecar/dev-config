#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

info() { printf "\033[1;34m[INFO]\033[0m %s\n" "$1"; }
success() { printf "\033[1;32m[OK]\033[0m %s\n" "$1"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$1"; }

# ---------------------------------------------------------------------------
# 1. Detect OS
# ---------------------------------------------------------------------------
OS="$(uname -s)"
info "Detected OS: $OS"

# ---------------------------------------------------------------------------
# 2. Install Homebrew (macOS / Linux)
# ---------------------------------------------------------------------------
if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for the rest of this script
    if [[ "$OS" == "Darwin" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
    success "Homebrew installed"
else
    success "Homebrew already installed"
fi

# ---------------------------------------------------------------------------
# 3. Install Oh My Zsh
# ---------------------------------------------------------------------------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    success "Oh My Zsh installed"
else
    success "Oh My Zsh already installed"
fi

# ---------------------------------------------------------------------------
# 4. Symlink dotfiles
# ---------------------------------------------------------------------------
link_file() {
    local src="$1"
    local dst="$2"

    if [[ -L "$dst" ]]; then
        rm "$dst"
    elif [[ -f "$dst" ]]; then
        warn "Backing up existing $dst to ${dst}.backup"
        mv "$dst" "${dst}.backup"
    fi

    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    success "Linked $dst -> $src"
}

info "Symlinking dotfiles..."

link_file "$DOTFILES_DIR/shell/.zshrc"        "$HOME/.zshrc"
link_file "$DOTFILES_DIR/git/.gitconfig"       "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/git/ignore"           "$HOME/.config/git/ignore"
link_file "$DOTFILES_DIR/gh/config.yml"        "$HOME/.config/gh/config.yml"

# VS Code settings — path differs by OS
if [[ "$OS" == "Darwin" ]]; then
    VSCODE_DIR="$HOME/Library/Application Support/Code/User"
else
    VSCODE_DIR="$HOME/.config/Code/User"
fi
mkdir -p "$VSCODE_DIR"
link_file "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_DIR/settings.json"

# Cursor settings — path differs by OS
if [[ "$OS" == "Darwin" ]]; then
    CURSOR_DIR="$HOME/Library/Application Support/Cursor/User"
else
    CURSOR_DIR="$HOME/.config/Cursor/User"
fi
mkdir -p "$CURSOR_DIR"
link_file "$DOTFILES_DIR/vscode/settings.json" "$CURSOR_DIR/settings.json"

# ---------------------------------------------------------------------------
# 5. Install Homebrew packages, casks, fonts, and VS Code extensions
# ---------------------------------------------------------------------------
if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
    info "Installing Homebrew packages from Brewfile..."
    # Remove deprecated homebrew/bundle tap if present (bundle is now in core)
    brew untap homebrew/bundle 2>/dev/null || brew untap Homebrew/homebrew-bundle 2>/dev/null || true
    # Temporarily disable exit on error to continue even if some casks fail
    set +e
    brew bundle --file="$DOTFILES_DIR/Brewfile"
    BUNDLE_EXIT_CODE=$?
    set -e
    
    if [[ $BUNDLE_EXIT_CODE -eq 0 ]]; then
        success "Brewfile installed"
    else
        warn "Brewfile installation completed with some errors. Some packages may have failed to install."
        warn "You can retry failed installations later with: brew bundle --file=\"$DOTFILES_DIR/Brewfile\""
    fi
else
    warn "No Brewfile found, skipping"
fi

# ---------------------------------------------------------------------------
# 6. Install Volta and default Node.js
# ---------------------------------------------------------------------------
if ! command -v volta &>/dev/null; then
    info "Installing Volta..."
    curl https://get.volta.sh | bash -s -- --skip-setup
    export VOLTA_HOME="$HOME/.volta"
    export PATH="$VOLTA_HOME/bin:$PATH"
    success "Volta installed"
else
    success "Volta already installed"
fi

info "Installing default Node.js (LTS) via Volta..."
volta install node@lts
success "Node.js LTS installed"

# ---------------------------------------------------------------------------
# 7. Set Zsh as default shell
# ---------------------------------------------------------------------------
if [[ "$SHELL" != *"zsh"* ]]; then
    info "Setting Zsh as default shell..."
    chsh -s "$(which zsh)"
    success "Default shell set to Zsh"
else
    success "Zsh is already the default shell"
fi

# ---------------------------------------------------------------------------
# 8. Apply macOS defaults
# ---------------------------------------------------------------------------
if [[ "$OS" == "Darwin" ]] && [[ -f "$DOTFILES_DIR/macos/defaults.sh" ]]; then
    info "Applying macOS system preferences..."
    bash "$DOTFILES_DIR/macos/defaults.sh"
    success "macOS defaults applied"
fi

# ---------------------------------------------------------------------------
# 9. Clone company repositories
# ---------------------------------------------------------------------------
DEV_DIR="$HOME/dev"
GITHUB_ORG="Dishop-SaaS"

REPOS=(
    "dishop-backend"
    "dishop-dashboard"
    "dishop-dashboard-app"
    "dishop-expo-app"
    "dishop-fleet-app"
    "dishop-order-webapp"
    "dishop-roulette"
)

info "Cloning $GITHUB_ORG repositories into $DEV_DIR..."
mkdir -p "$DEV_DIR"

for repo in "${REPOS[@]}"; do
    if [[ -d "$DEV_DIR/$repo" ]]; then
        success "$repo already cloned"
    else
        info "Cloning $repo..."
        gh repo clone "$GITHUB_ORG/$repo" "$DEV_DIR/$repo" -- --recurse-submodules
        success "$repo cloned"
    fi
done

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
success "Dotfiles installation complete!"
echo ""
info "Open a new terminal to apply all changes."
