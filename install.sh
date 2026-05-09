#!/usr/bin/env bash
# TODO: Test the script on a VM.
#
# -e: Exit immediately if a command fails.
# -u: Exit if you try to use an uninitialized variable.
# -o pipefail: Ensure that pipes return the exit code of the first failing command.
set -euo pipefail 

# Standard way to catch and move into the dir where the script lives (the repo root).
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

    # ${2:+($2) } => if there is second param add it.
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

# function for setting up the most common case of dotfiles where they live in the ~ dir.
function symlink_config() {
    local file_name="$1"
    local source_path="${SCRIPT_DIR}/${file_name}"
    local dest_path="$HOME/${file_name}"

    # Check if it's already a symlink pointing to the repo
    if [[ -L "$dest_path" ]]; then
        # readlink prints the name of the original file of the symlink
        if [[ "$(readlink "$dest_path")" == "$source_path" ]]; then
            echo "$file_name already symlinked correctly."
            echo "Skipping."
            return
        fi
    fi

    # If file or other symlink exists, back it up
    if [[ -e "$dest_path" || -L "$dest_path" ]]; then
        echo "$file_name exists. Moving to backup: ${DOTFILES_BK_PATH}/${file_name}.bk"
        # Ensure backup dir exists (because of "-p" flag, mkdir exit status is 0 even if dir exists)
        mkdir -p "$DOTFILES_BK_PATH"
        # Move the existing file/link
        mv "$dest_path" "${DOTFILES_BK_PATH}/${file_name}.bk"
    fi

    # Create the symlink
    ln -s "$source_path" "$dest_path"
    echo "$file_name setup successfully."
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

# setup essentials.
for file in .profile .bashrc .bash_aliases; do
    if prompt_if_auto_setup_false "$file"; then
        symlink_config "$file"
    fi
done

# package managers

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
if prompt_if_auto_setup_false "npm" $'Dependencies: nvm \nRequired for: gemini-cli. \nInstalled later from the installer.'; then
    ensure_pm_installed "nvm" "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash"
    # setup and source nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    nvm install --lts
fi

# cargo => If a tool is written in rust its probably faster and safer. Cargo has nice ux too. If i can install smth from cargo i prefer it every time.
if prompt_if_auto_setup_false "cargo" $'Required for: \nripgrep, \nfd-find, \neza, \ntree-sitter-cli, \nneovim. \nInstalled later from the installer.'; then
    ensure_pm_installed "cargo" "curl https://sh.rustup.rs -sSf | sh"
    # source cargo
    source "$HOME/.cargo/env"

    # cargo-binstall => allows binary installations for rust projects. (also this versions of the tools are more stable and tested from the developers)
    ensure_pm_installed "cargo-binstall" "cargo install --locked cargo-binstall"
fi

# tools & apps

# fzf (update cmnds => "cd ~/.fzf && git pull && ./install")
if prompt_if_auto_setup_false "fzf" $'Required for: \nneovim, \nhistory integration (ctrl+r) \nInstalled later from the installer.'; then
    # the "if" check makes it idempotent (required because of "set -e" at the start of the script).
    if [[ ! -d "$HOME/.fzf" ]]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    fi
    # "--all" flag setups the config at ~/.fzf.bash and ~/.fzf (autocomplete, history integration, etc)
    ~/.fzf/install --all
fi

# tmux
if prompt_if_auto_setup_false "tmux"; then
    sudo apt install tmux
    symlink_config ".tmux.conf"
fi

if prompt_if_auto_setup_false "alacritty"; then
    sudo apt install alacritty
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
if prompt_if_auto_setup_false "tree-sitter-cli" $'Dependencies:\n clang (handled by the installer if you confirm to install tree-sitter-cli) \nRequired for: neovim \nInstalled later from the installer.'; then
    # dependencies: clang
    sudo apt install clang libclang-dev
    pm_install_package "cargo" "binstall" "tree-sitter-cli"
fi

# eza
if prompt_if_auto_setup_false "eza"; then
    pm_install_package "cargo" "binstall" "eza"
fi

# gemini-cli
if prompt_if_auto_setup_false "gemini-cli"; then
    pm_install_package "npm" "install" "-g" "@google/gemini-cli"
fi

# neovim
# bob is a neovim package manager (like nvm is for npm)
if prompt_if_auto_setup_false "neovim"; then
    pm_install_package "cargo" "binstall" "bob-nvim"
    source "$HOME/.cargo/env"
    bob install stable && bob use stable

    # kickstart => a couple of plugins + really friendly docs for setting up nvim (maintained by a core nvim maintainer)
    if prompt_if_auto_setup_false "kickstart" "Neovim starter configuration (best way to learn how to configure neovim. See kickstart on github."; then
        NVIM_CONFIG_DIR="$HOME/.config/nvim"
        if [[ ! -d $NVIM_CONFIG_DIR ]]; then
            git clone https://github.com/nvim-lua/kickstart.nvim.git "$NVIM_CONFIG_DIR"
        fi
    fi
fi

echo $'\nSetup passed successfuly!'
exit 0
