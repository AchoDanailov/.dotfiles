#!/usr/bin/env bash

# -e: Exit immediately if a command fails.
# -u: Exit if you try to use an uninitialized variable.
# -o pipefail: Ensure that pipes return the exit code of the first failing command.
set -euo pipefail

# Standard bash-ism way to catch and move into the dir where the script lives (the repo root).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_BK_PATH="$HOME/.dotfiles_bk_$(date +%Y-%m-%d-%H-%M)"
AUTO_SETUP_ALL=false

function show_usage() {
    echo "Usage:"
    echo "$0 [OPTIONS]"
    echo $'\nOptions:'
    echo $'--auto-setup-all=true | false \t If set to "true" this option executes the installer without prompting on each configuration/tool. Default value: false. See README.md for info on what is being installed and setup.'.
}

function prompt_if_auto_setup_false() {
    if [[ "$AUTO_SETUP_ALL" == "true" ]]; then
        return 0
    fi

    # ${2:+$2 } => if there is second param add it.
    local prompt=$'\n'"Setup $1? ${2:+$2 }[Y, n]"
    # read - read user input (-p flag - inline)
    # ${} - parameter expansion (for normal cases works like doing $var_name, in this case - ${var_name^^} changes casing to upper case.)
    read -p "${prompt}" result

    local res="${result^^}"
    if [[ -z "$res" || "$res" == "Y" || "$res" == "YES" ]]; then
        return 0
    fi

    return 1
}

function symlink_to_path() {
    local source_path="$1"
    local dest_path="$2"

    if [[ -L "$dest_path" ]]; then
        # readlink prints the name of the original file of the symlink
        if [[ "$(readlink "$dest_path")" == "$source_path" ]]; then
            echo "\"$dest_path\" -> \"$source_path\" symbolic link exists already."
            echo $'Skipping.'
            return
        fi
    fi

    if [[ -e "$dest_path" || -L "$dest_path" ]]; then
        # =~ is the operator for regex pattern matching
        if [[ "$dest_path" =~ ^/ ]]; then
            local backup_dest="${DOTFILES_BK_PATH}${dest_path}.bk"
        else
            local backup_dest="${DOTFILES_BK_PATH}/${dest_path}.bk"
        fi

        # Ensure backup dir exists (this wont throw because of "-p" flag, mkdir exit status is 0 even if dir exists. See: man mkdir)
        mkdir -p "$(dirname "$backup_dest")"
        echo "$dest_path exists. Moving to backup: $backup_dest"
        mv "$dest_path" "$backup_dest"
    fi

    mkdir -p "$(dirname "${dest_path}")"
    ln -s "$source_path" "$dest_path"
    echo "\"$dest_path\" -> \"$source_path\" symbolic link setup successfully."
}

function ensure_pm_installed() {
    local package_manager="$1"
    local install_script="$2"

    # command -v "cmd" prints out the cmd name and returns status code 0 if the cmd is found
    if command -v "$package_manager" &> /dev/null; then
        echo "$package_manager is already installed."
        return
    fi

    echo "Installing $package_manager."
    eval "$install_script"
}

function pm_install_package() {
    local pm="$1"
    if ! command -v "$pm" &> /dev/null; then
        echo "$pm was not found. Please install $pm first."
        return
    fi

    # !!
    shift

    # example: $pm=npm $@=("install", "-g", "@google/gemini-cli") => npm install -g @google/gemini-cli"
    $pm "$@"
    # "${@: -1} => parameter expansion + @ all args + -1 last arg (last arg always the package being installed.
    echo "${@: -1} installed successfully."
}

# args parsing.
if [[ $# == 0 ]]; then
    AUTO_SETUP_ALL=false
elif [[ $# == 1 ]]; then
    if [[ "$1" == "--auto-setup-all=true" ]]; then
        AUTO_SETUP_ALL=true
    elif [[ "$1" == "--auto-setup-all=false" ]]; then
        AUTO_SETUP_ALL=false
    else
        echo "Invalid usage!"
        show_usage
        exit 2
    fi
else
    echo "Invalid usage!"
    show_usage
    exit 2
fi

# setup home dotfiles
for file in .profile .bashrc .bash_aliases .gitconfig; do
    if prompt_if_auto_setup_false "$file"; then
        symlink_to_path "${SCRIPT_DIR}/${file}" "${HOME}/${file}"
    fi
done

# vscode's user setting.json (still requires installation of vscode seperately)
if prompt_if_auto_setup_false "settings.json" $'\nVSCodes User settings.json file.\nPath: ~/.config/Code/User/settings.json\nNOTE: The installed does not install VSCode. If you want to install VSCode, see: "https://code.visualstudio.com/download".';
then
    symlink_to_path "${SCRIPT_DIR}/settings.json" "$HOME/.config/Code/User/settings.json"
fi

# vscode's "Custom CSS and JS" extension css file (if "Custom CSS and JS" extension is installed this file will modify vscode editor styles. See "Custom CSS and JS" extension.)
if prompt_if_auto_setup_false "editor_custom_layout.css" $'\nVSCode\'s "Custom CSS and JS" extension file.\nThis file will modify VSCode\'s layout.\nTo get it running see "Custom CSS and JS" extension.\nPath: ~/.vscode/editor_custom_layout.css\nNOTE: The installed does not install VSCode. If you want to install VSCode, see: "https://code.visualstudio.com/download".';
then
    symlink_to_path "${SCRIPT_DIR}/editor_custom_layout.css" "$HOME/.vscode/editor_custom_layout.css"
fi

# JetBrains rider's plugin `VimIdea` .ideavimrc configuration file
if prompt_if_auto_setup_false ".vimidearc" $'\nJetBrains Rider\'s VimIdea plugin configuration file.'; then
    symlink_to_path "${SCRIPT_DIR}/.vimidearc" "$HOME/.vimidearc"
fi

# update && upgrade apt
echo $'\nUpdating system package manager: apt'
sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y

# make, gcc, cc (required for cargo)
if prompt_if_auto_setup_false "make, gcc, cc" $'\nRequired for cargo.\nInstalled and used later in the installer.'; then
    sudo apt install build-essential
fi

# curl
if prompt_if_auto_setup_false "curl" $'\nRequired for npm and cargo.\nInstalled and used later in the installer.'; then
    sudo apt install curl
fi

# nvm => required on most Debian based distros to install latest versions of node and npm (which are likely required if u want to use modern ts for example) (same commands for update)
#npm
if prompt_if_auto_setup_false "npm"; then
    ensure_pm_installed "nvm" "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash"
    # setup and source nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    nvm install --lts
fi

# NOTE: Keep in mind this might introduce long term problems. Since the install.sh script is relying on cargo way too much.
# TODO: Almost all the tools installed with cargo can be installed from the original repo. Think about which is better package manager vs github source repo.
if prompt_if_auto_setup_false "cargo" $'Required for: \nripgrep, \nfd-find, \neza, \ntree-sitter-cli, \nneovim. \nInstalled later from the installer.';
then
    ensure_pm_installed "cargo" "curl https://sh.rustup.rs -sSf | sh"
    source "$HOME/.cargo/env"

    # cargo-binstall => allows binary installations for rust projects. (also this versions of the tools are more stable and tested from the developers compared to cargo install)
    ensure_pm_installed "cargo-binstall" "cargo install --locked cargo-binstall"
fi

# fzf (update cmnds => "cd ~/.fzf && git pull && ./install")
if prompt_if_auto_setup_false "fzf" $'Required for: \nneovim, \nhistory integration (ctrl+r) \nInstalled later from the installer.'; then
    # the "if" check makes it idempotent (required because of "set -e" at the start of the script).
    if [[ ! -d "$HOME/.fzf" ]]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    fi
    # "--all" flag setups the config at ~/.fzf.bash and ~/.fzf (autocomplete, history integration, etc)
    ~/.fzf/install --all
fi

# gh cli
if prompt_if_auto_setup_false "gh"; then
    sudo apt install gh
fi

# ncdu
if prompt_if_auto_setup_false ncdu; then
    sudo apt install ncdu
fi

# htop
if prompt_if_auto_setup_false htop; then
    sudo apt install htop
fi

# tmux
if prompt_if_auto_setup_false "tmux"; then
    sudo apt install tmux
    symlink_to_path "${SCRIPT_DIR}/.tmux.conf" "${HOME}/.tmux.conf"
fi

# alacritty
if prompt_if_auto_setup_false "alacritty"; then
    sudo apt install alacritty

    if prompt_if_auto_setup_false $'\nInstalled successfully!\nDo you want to setup Alacrity configuration file (path: ~/.config/alacritty/alacritty.toml)?\n[Y, n]'; 
    then
        symlink_to_path "${SCRIPT_DIR}/alacritty.toml" "${HOME}/.config/alacritty/alacritty.toml"
    fi
fi

# ripgrep
if prompt_if_auto_setup_false "ripgrep" $'Required for: neovim \nInstalled later from the installer.'; then
    pm_install_package "cargo" "binstall" "ripgrep"
fi

# fd-find
if prompt_if_auto_setup_false "fd-find" $'Required for: neovim \nInstalled later from the installer.'; then
    pm_install_package "cargo" "binstall" "fd-find"
fi

# tree-sitter-cli
if prompt_if_auto_setup_false "tree-sitter-cli" $'Dependencies:\n clang (handled by the installer if you confirm to install tree-sitter-cli) \nRequired for: neovim \nInstalled later from the installer.';
then
    # dependencies: clang
    sudo apt install clang libclang-dev
    pm_install_package "cargo" "binstall" "tree-sitter-cli"
fi

# eza
if prompt_if_auto_setup_false "eza"; then
    pm_install_package "cargo" "binstall" "eza"
fi

# neovim
# bob is a neovim package manager (like nvm is for npm)
if prompt_if_auto_setup_false "neovim"; then
    pm_install_package "cargo" "binstall" "bob-nvim"
    source "$HOME/.cargo/env"
    bob install stable && bob use stable

    # kickstart.nvim => a couple of plugins + really friendly docs for setting up nvim (maintained by a core nvim maintainer)
    if prompt_if_auto_setup_false "kickstart" "Neovim starter configuration (best way to learn how to configure neovim. See kickstart on github.";
    then
        NVIM_CONFIG_DIR="$HOME/.config/nvim"
        if [[ ! -d $NVIM_CONFIG_DIR ]]; then
            git clone https://github.com/nvim-lua/kickstart.nvim.git "$NVIM_CONFIG_DIR"
        fi
    fi
fi

# opencode
if prompt_if_auto_setup_false "opencode"; then
    curl -fsSL https://opencode.ai/install | bash
fi


echo $'\nSetup passed successfuly!'
exit 0
