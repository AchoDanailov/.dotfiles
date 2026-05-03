#!/usr/bin/env bash

# Esentials
for file in .profile .bashrc .tmux.conf; do
    cd ~

    if [[ -f $file ]]; then
        mv $file ~/dotfiles
    fi

    if [[ -f ~/dotfiles/$file ]]; then
        ln -s "$HOME/dotfiles/$file" "$HOME/$file"
    fi
done
