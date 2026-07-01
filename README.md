# My personal dotfiles + my environment setup scripts.

## Description

These are my personal dotfiles. And it goes beyond just my dotfiles, by adding an installer program that automates alot of the first couple of hours installation and configuration of tools that happens when you start working on a new machine.

### What is included

#### **Config files and Dotfiles:**
- .profile
- .bashrc
- .bash_aliases
- .tmux.conf
- .gitconfig
- settings.json (VSCode's User settings.json. Path: ~/.config/Code/User/settings.json)
- .ideavimrc (JetBrains Rider\'s VimIdea plugin configuration file)
- alacritty.toml (Alacritty's config file. Path: ~/.config/alacritty/alacritty.toml)

#### **Tools:**
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
- [opencode](https://github.com/anomalyco/opencode/)
- [neovim](https://github.com/neovim/neovim) + [kickstart](https://github.com/nvim-lua/kickstart.nvim)

#### **Installer script - `install.sh`**
- Installs the cli tools that I use, installs their dependencies if any and sets up everything related to the environment variables if there is any setup to be done.
- When ran starts asking for confirmation for each tool or config file and then installs or symlinks the tool or config file (or skips if confirmation was not given).
- If a config file or symlink pointing to some other file exists already it is backed up under `~/.dotfiles_bk_(current date and time)`.
- If a symlink is found that points to a file in the repo source that config file is skipped.
- It is idempotent (it can be ran safely multiple times)

---

**Note: The installer heavily relies on the APT and Cargo package managers for installing software packages and dependencies.**

**The installer has been tested on:**
- Pop!_OS 24.04 (which is on top of Ubuntu 24.04),
- Ubuntu 26.04

---

## Setup and Usage

```bash
git clone https://github.com/AchoDanailov/.dotfiles.git
cd .dotfiles
chmod u+x install.sh && ./install.sh
```
**Important: Review the code and decide if you want to run it yourself!**

### Options
`install.sh`
- `--auto-setup-all=true|false` - skips the prompts that are not package managers prompts (default value: false)

---

## License
MIT
