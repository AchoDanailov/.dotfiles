# My personal dotfiles + my environment setup scripts.

## Description

These are my personal dotfiles. And it goes beyond just my dotfiles. 

### What is included

#### Dotfiles included:
- .profile
- .bashrc
- .bash_aliases
- .tmux.conf
- .gitconfig

#### Tools included:
- [curl](https://github.com/curl/curl)
- [fzf](https://github.com/junegunn/fzf) - improves searching through the commands history(ctrl+r) and is required for kickstart.nvim
- [gh](https://cli.github.com/) - GitHub CLI
- ncdu
- htop
- [tmux](https://github.com/tmux/tmux)
- [alacritty](https://github.com/alacritty/alacritty)
- [ripgrep](https://github.com/BurntSushi/ripgrep) - better grep
- [fd-find](https://github.com/sharkdp/fd) - better find
- [eza](https://github.com/eza-community/eza) - better ls
- [gemini-cli](https://github.com/google-gemini/gemini-cli)
- [neovim](https://github.com/neovim/neovim) + [kickstart](https://github.com/nvim-lua/kickstart.nvim)

#### Installer script - `install.sh`
- Installs the cli tools that I use, installs their dependencies if any and sets up everything related to the environment variables if there is any setup to be done.
- When ran starts asking for confirmation for each tool or config file and then installs or symlinks the tool or config file (or skips if confirmation was not given).
- If a config file or symlink pointing to some other file exists already it is backed up under `~/.dotfiles_bk_(current date and time)`.
- If a symlink is found that points to a file in the repo source that config file is skipped.
- It is idempotent (it can be ran safely multiple times)  

**Note: This script currently only supports Debian-based distributions as it relies on the APT package manager.**

---

## Setup and Usage

```bash
git clone https://github.com/AchoDanailov/.dotfiles.git   
cd .dotfiles  
chmod u+x install.sh && ./install.sh  
```

### Options
`install.sh`
- `--auto-setup-all=true|false` - skips the prompts that are not package managers prompts (default value: false)

---

## License
MIT