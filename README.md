# Dev Container Base

Reusable dev container template for any project.

## Included Tools

### Base CLI
- **Search**: ripgrep, fzf, fd
- **Terminal**: tmux, yazi, starship
- **Git**: lazygit, gh
- **Editor**: neovim
- **Utils**: jq, eza, zoxide, lsof, stow

### Package Managers
- **Homebrew**: package manager
- **mise**: runtime version manager (Node, Python, Go, etc.)

### Shell
- zsh + oh-my-zsh
- Plugins: autosuggestions, syntax-highlighting

### AI
- Claude Code CLI

## Usage

### 1. Copy to your project

```bash
cp -r devcontainer/* your-project/
cp -r devcontainer/.claude your-project/
cp devcontainer/.gitignore your-project/
```

### 2. Create .env

```bash
cd your-project
cp .env.example .env
# Edit .env with your personal settings
```

**Available settings (defaults in .env.example):**

| Variable | Description | Default |
|----------|-------------|---------|
| `DOTFILES_REPO` | URL of your dotfiles repository | `` |
| `DOTFILES_BRANCH` | Dotfiles branch | `main` |
| `DOTFILES_STOW_EXCLUDE` | Packages to exclude from stow | `ghostty,waybar` |
| `GIT_USER_NAME` | Name for git config | `` |
| `GIT_USER_EMAIL` | Email for git config | `` |
| `ANTHROPIC_API_KEY` | API key for Claude Code | `` |
| `DEFAULT_SHELL` | Default shell (zsh/bash) | `zsh` |
| `TMUX_AUTO_START` | Auto-start tmux | `true` |
| `TMUX_SESSION_NAME` | Tmux session name | `main` |
| `MISE_AUTO_TRUST` | Auto-trust mise.toml | `true` |

### 3. Create project-dependencies.sh

```bash
cd your-project
cp project-dependencies.sh.template project-dependencies.sh
# Edit as needed
```

### 4. Add ports (if needed)

Edit `devcontainer.json`:
```json
{
  "forwardPorts": [3000, 8080]
}
```

Edit `docker-compose.yml`:
```yaml
ports:
  - "3000:3000"
  - "8080:8080"
```

### 5. Open in VS Code

```bash
code your-project
# F1 > "Dev Containers: Reopen in Container"
```

## Examples of project-dependencies.sh

### Python Project
```bash
mise use python@3.11
pip install -r requirements.txt
```

### Node.js Project
```bash
mise use node@20
npm install
```

### Project with Browser Testing
```bash
mise use python@3.11
sudo apt-get update && sudo apt-get install -y \
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libdrm2 libxkbcommon0 libxcomposite1 \
    libxdamage1 libxfixes3 libxrandr2 libgbm1 \
    libasound2 libpango-1.0-0 libcairo2 libatspi2.0-0
pip install playwright
playwright install chromium
```
