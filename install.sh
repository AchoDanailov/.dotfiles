#!/usr/bin/env bash
# TODO: Test the script on a VM.
#
# -e: Exit immediately if a command fails.
# -u: Exit if you try to use an uninitialized variable.
# -o pipefail: Ensure that pipes return the exit code of the first failing command.
set -euo pipefail 

# Standard way to catch the path of where the script lives (the repo root).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
auto_setup_all=false
setup_symlinks=""

function show_usage() {
    echo "Usage:"
    echo "$0 [OPTIONS]"
    echo $'\nOptions:'
    echo $'--auto-setup-all=true | false \t If set to "true" this option executes the installer without prompting on each configuration/tool. Default value: false'.
}

# function gets invoked with command substituion and assigned in a variable (common bash pattern to return values from a function)
function prompt_for_section_setup() {
    # read - read user input (-p flag - inline)
    # ${} - parameter expansion (for normal cases works like doing $var_name, in this case - ${var_name^^} changes casing to upper case.)
    read -p "Setup $1? [Y, n]" result 
    echo "${result^^}"
}

# function for setting up the most common case of dotfiles where they live in the ~ dir.
function setup() {
    local dotfiles_backup_path="$HOME/.dotfiles_bk_$(date +%Y-%m-%d)"

    # create backup if file/dir exists
    if [[ -e "$HOME/$1" ]]; then
        echo "$1 exists on the current machine. Creating backup. Backup destination: ${dotfiles_backup_path}/$1.bk"

        if [[ ! -d "$dotfiles_backup_path" ]]; then
            mkdir -p "$(dirname "${dotfiles_backup_path}/$1")"
        fi

        mv "$HOME/$1" "${dotfiles_backup_path}/$1.bk"
    fi

    # if setup symlinks is chosen => ensure ~/.dotfiles exist, cp file from repo to ~/.dotfiles, symlink to ~
    # if setup symlinks is not chosen => cp file from repo to ~
    if [[ "${setup_symlinks^^}" == "Y" || "${setup_symlinks^^}" == "YES" || "${setup_symlinks}" == "" ]]; then
        if [[ ! -d "$HOME/.dotfiles" ]]; then
            mkdir -p "$HOME/.dotfiles"
        fi
        
        cp -r "${SCRIPT_DIR}/$1" "$HOME/.dotfiles/$1"
        ln -s "$HOME/.dotfiles/$1" "$HOME/$1"
    else
        cp "$SCRIPT_DIR/$1" "$HOME/$1"
    fi
}

# args parsing.
if [[ $# == 0 ]]; then
    auto_setup_all=false
elif [[ $# == 1 ]]; then
    if [[ "$1" == "--auto-setup-all=true" ]]; then 
        auto_setup_all=true
    elif [[ "$1" == "--auto-setup-all=false" ]]; then
        auto_setup_all=false

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

# prompt for symlink creation
# Can be improved by introducing an arr of all the files that are being setup and then at the end prompt for symlinks once the files are known to the program user.
while true; do
    read -p "Setup symlinks in $HOME/.dotfiles ? [Y, n]" setup_symlinks_result

    if [[ ${setup_symlinks_result^^} == "N" ||
        ${setup_symlinks_result^^} == "NO" ||
        ${setup_symlinks_result^^} == "Y" ||
        ${setup_symlinks_result^^} == "YES" ||
        ${setup_symlinks_result} = "" ]]
    then
        # setup_symlinks is a script global variable (check on top of the script)
        setup_symlinks="$setup_symlinks_result"
        break;
    fi

    echo "Invalid input. Valid inputs: Y and N. Default value: Y."
done

if [[ $auto_setup_all == true ]]; then
    for file in .profile .bashrc; do
        setup "$file"
    done

#    setup_tool_with_dependencies tmux

    echo "Setup passed successfuly!"
    exit 0
fi

# .profile
result=$(prompt_for_section_setup ".profile")
if [[ $result == "Y" || $result == "YES" ]]; then
    setup .profile
fi

# .bashrc
result=$(prompt_for_section_setup ".bashrc")
if [[ $result == "Y" || $result == "YES" ]]; then
    setup .bashrc
fi

## tmux
#result=$(prompt_for_section_setup ".tmux.conf")
#if [[ $result == "Y" || $result == "YES" ]]; then
#    setup_tool_with_dependencies tmux 
#fi
#
## alacritty
#result=$(prompt_for_section_setup "alacritty")
#if [[ $result == "Y" || $result == "YES" ]]; then
#    setup_tool_with_dependencies alacritty
#fi

echo "Setup passed successfuly!"
exit 0
