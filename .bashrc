# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash-examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
       *) return;;
esac

# --- PATH ---
export PATH="$HOME/bin:$PATH"
export PATH="$PATH:/opt/nvim/"
export PATH="$PATH:/opt/rider/bin/"
export PATH="$PATH:$HOME/.local/share/bob/nvim-bin"
export PATH=/home/danailov/.opencode/bin:$PATH

# --- ENVIRONMENT ---
export EDITOR=nvim
export LANG=en_US.UTF-8
export LS_OPTIONS='--color=auto'
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# --- HISTORY ---
HISTSIZE=5000
HISTFILESIZE=10000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# --- LESS OPTIONS ---
export LESSHISTFILE=/dev/null

# --- SHELL OPTIONS ---
shopt -s checkwinsize   # auto-update terminal size
shopt -s autocd         # type dir name to cd
shopt -s cdspell        # auto-correct minor cd typos
shopt -s globstar       # recursive ** support
bind "set completion-ignore-case on"
set -o vi

# --- PROMPT ---
# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

parse_git_branch() {
    branch=$(git branch --show-current 2>/dev/null)
    if [[ -n "$branch" && "$branch" != *"fatal"* ]]; then
       echo " git:($branch)"
    fi
}

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]$(parse_git_branch)\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$$(parse_git_branch)\$ '
fi

unset color_prompt force_color_prompt

case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# number of directories up the tree that are shown in the prompt.
PROMPT_DIRTRIM=2

# --- COLORS ---
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi
eval "$(dircolors)"

# "." char means "source" in POSIX standard ("source" is bash version)
# --- EXTERNAL FILES ---
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if ! shopt -oq posix; then
   if [ -f /usr/share/bash-completion/bash_completion ]; then
     . /usr/share/bash-completion/bash_completion
   elif [ -f /etc/bash_completion ]; then
     . /etc/bash_completion
   fi
fi

if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# --- TOOLS ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# gh completions
eval "$(gh completion -s bash)"
