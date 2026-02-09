# dev-config

Personal dev environment configuration. One script to set up any new Mac (or Linux/WSL machine).

## What's included

- **Shell** — Zsh with Oh My Zsh, robbyrussell theme
- **Git** — User config, LFS, global gitignore, aliases, pull rebase, default branch
- **VS Code & Cursor** — Dracula theme, JetBrains Mono font, extensions (shared settings)
- **GitHub CLI** — Config with aliases
- **Homebrew** — All packages, casks, fonts, and VS Code extensions via Brewfile
- **Volta** — Node.js version manager with LTS pre-installed
- **Font** — JetBrains Mono Nerd Font (installed via Homebrew)
- **macOS** — System preferences (Dock, Finder, keyboard, screenshots, trackpad)
- **Company repos** — Auto-clones all Dishop-SaaS repositories into `~/dev/`

## Prerequisites: Setting up SSH keys

**IMPORTANT:** Before cloning this repository, you need to set up SSH keys for GitHub. The install script uses SSH to clone repositories, so SSH authentication must be configured first.

### Step 1: Generate a new SSH key

```bash
ssh-keygen -t ed25519 -C "carlos@ciggy-app.com"
```

When prompted:
- **File location**: press Enter to accept the default (`~/.ssh/id_ed25519`)
- **Passphrase**: enter a secure passphrase (recommended) or press Enter to skip

### Step 2: Start the SSH agent and add your key

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

To avoid running this every time you open a terminal, add the key to the macOS Keychain:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

### Step 3: Log in to GitHub CLI

```bash
gh auth login
```

When prompted, select:
- **GitHub.com**
- **SSH** as the preferred protocol
- Select the key you just created
- **Login with a web browser** (easiest option)

### Step 4: Add the SSH key to your GitHub account

```bash
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)"
```

### Step 5: Verify the connection

```bash
ssh -T git@github.com
```

You should see: `Hi varlopecar! You've successfully authenticated`.

### Step 6: (Optional) Create an SSH config file

Create `~/.ssh/config` to avoid re-entering settings:

```bash
cat <<EOF > ~/.ssh/config
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
chmod 600 ~/.ssh/config
```

This ensures the SSH agent uses the macOS Keychain and your key is loaded automatically on every terminal session.

## Quick start

Once SSH keys are set up, clone and install:

```bash
git clone git@github.com:varlopecar/dev-config.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## What the install script does

1. Installs Homebrew (if not present)
2. Installs Oh My Zsh (if not present)
3. Symlinks all config files to their expected locations
   - Shell: `~/.zshrc`
   - Git: `~/.gitconfig`, `~/.config/git/ignore`
   - GitHub CLI: `~/.config/gh/config.yml`
   - VS Code: `~/Library/Application Support/Code/User/settings.json`
   - Cursor: `~/Library/Application Support/Cursor/User/settings.json`
4. Runs `brew bundle` to install packages, casks, fonts, and VS Code extensions
5. Installs Volta and Node.js LTS
6. Sets Zsh as the default shell
7. Applies macOS system preferences (Dock, Finder, keyboard, screenshots)
8. Clones all Dishop-SaaS company repositories into `~/dev/` (requires SSH keys to be set up first)

## Project structure

```
dotfiles/
├── Brewfile                 # Homebrew packages, casks, fonts, extensions
├── install.sh               # Main setup script
├── README.md
├── .gitignore
├── gh/
│   └── config.yml           # GitHub CLI config
├── git/
│   ├── .gitconfig           # Git user, aliases, LFS, pull strategy
│   └── ignore               # Global gitignore
├── macos/
│   └── defaults.sh          # macOS system preferences
├── shell/
│   └── .zshrc               # Zsh config with Oh My Zsh
└── vscode/
    └── settings.json        # Shared VS Code & Cursor settings
```


## Git aliases

The `.gitconfig` includes these aliases:

| Alias | Command | Description |
|---|---|---|
| `git co` | `checkout` | Switch branches |
| `git st` | `status` | Show status |
| `git br` | `branch` | List/manage branches |
| `git cm` | `commit` | Commit changes |
| `git lg` | `log --oneline --graph` | Pretty log with graph |
| `git last` | `log -1 HEAD` | Show last commit |
| `git undo` | `reset --soft HEAD~1` | Undo last commit (keep changes) |
| `git amend` | `commit --amend --no-edit` | Amend last commit |

## macOS defaults

The `macos/defaults.sh` script configures:

- **Dock**: auto-hide, no recents, fast animations, icon size 48px
- **Finder**: show extensions, hidden files, path bar, list view, folders first
- **Keyboard**: fast key repeat, short delay, no auto-correct/capitalize
- **Screenshots**: PNG format, saved to `~/Desktop/Screenshots`, no shadow
- **Trackpad**: tap to click, three-finger drag
- **Misc**: expanded save/print panels, no .DS_Store on network/USB

## Updating

When you change a config on your machine, the symlinked files in `~/dotfiles/` are already updated. Just commit and push:

```bash
cd ~/dotfiles
git add -A
git commit -m "update configs"
git push
```

To regenerate the Brewfile after installing new packages:

```bash
brew bundle dump --file=~/dotfiles/Brewfile --force
```
