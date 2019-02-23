autoload -Uz compinit colors vcs_info
colors

typeset -i updated_at=$(date +'%j' -r ~/.zcompdump 2>/dev/null || stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)
if [ $(date +'%j') != $updated_at ]; then
  compinit -i
else
  compinit -C -i
fi

zmodload -i zsh/complist

REPORTTIME=3

HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=$HISTSIZE

setopt inc_append_history
setopt extended_history
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt hist_ignore_space
setopt share_history

setopt auto_cd

setopt correct_all
setopt auto_list
setopt auto_menu
setopt always_to_end

setopt prompt_subst

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git*' formats "%F{yellow}%b%f %m%u%c"
zstyle ':vcs_info:git*' actionformats "%F{yellow}%b%f %F{red}•%a%f  %m%u%c"

zstyle ':vcs_info:*' unstagedstr '%F{yellow}!%f'
zstyle ':vcs_info:*' stagedstr '%F{green}+%f'

zstyle ':vcs_info:git*+set-message:*' hooks clear-misc git-st git-untracked
+vi-clear-misc() {
    hook_com[misc]=""
}

+vi-git-untracked() {
    if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
        git status --porcelain | grep '??' &> /dev/null ; then
        hook_com[misc]+='%F{red}?%f'
    fi
}

+vi-git-st() {
    local ahead behind ahead_fmt behind_fmt
    local -a gitstatus

    ahead=$(git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l | tr -d ' ')
    (( $ahead )) && ahead_fmt=$(echo "${ahead}" | sed 's/1/¹/g; s/2/²/g; s/3/³/g; s/4/⁴/g; s/5/⁵/g; s/6/⁶/g; s/7/⁷/g; s/8/⁸/g; s/9/⁹/g; s/0/⁰/g;') && gitstatus+=( "%F{blue}↑${ahead_fmt}%f " )

    behind=$(git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l | tr -d ' ')
    (( $behind )) && behind_fmt=$(echo "${behind}" | sed 's/1/₁/g; s/2/₂/g; s/3/₃/g; s/4/₄/g; s/5/₅/g; s/6/₆/g; s/7/₇/g; s/8/₈/g; s/9/₉/g; s/0/₀/g;') && gitstatus+=( "%F{blue}↓${behind_fmt}%f " )

    hook_com[misc]+="${gitstatus}"
}
precmd () {
    vcs_info
}

function ssh_prompt () {
    if [[ -n $SSH_CONNECTION ]]; then
        echo '%F{blue}⟮𝐬𝐬𝐡⟯%f '
    fi
}

function user_host_prompt () {
    if [[ -n $SSH_CONNECTION ]]; then
        local fqdn
	fqdn=$(hostname -f)
        if [[ $UID -eq 0 ]]; then
            echo "%B%F{yellow}⚠ %n@${fqdn}%f%b "
        else
            echo "%B%F{white}%n@${fqdn}%f%b "
        fi
    else
        if [[ $UID -eq 0 ]]; then
            echo '%B%F{yellow}⚠ %n%f '
        fi
    fi
}

function pwd_prompt () {
  echo '%B%F{cyan}%(4~|…/%3~|%~)%f%b '
}

PROMPT=$'$(ssh_prompt)$(user_host_prompt)$(pwd_prompt)${vcs_info_msg_0_}%E\n%B%(?.%F{green}.%F{red})⮞%f%b%E '

# user-friendly command output
export CLICOLOR=1
ls --color=auto &> /dev/null && alias ls='ls --color=auto'
alias l='ls -a -l -F -h'

NEW_PATH="$PATH"

if [ -d "/usr/local/sbin" ]; then
    NEW_PATH="/usr/local/sbin:$NEW_PATH"
fi

if [ -d "$HOME/.rbenv/bin" ]; then
    NEW_PATH="$HOME/.rbenv/bin:$NEW_PATH"
fi

if [ -d "$HOME/.local/bin" ]; then
    NEW_PATH="$HOME/.local/bin:$NEW_PATH"
fi

export PATH="$NEW_PATH"

if [ -x "$(command -v rbenv)" ]; then
    eval "$(rbenv init -)"
fi

if [ -f "/proc/sys/kernel/osrelease" ] && grep -q Microsoft /proc/sys/kernel/osrelease; then
    export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
    unsetopt bg_nice
fi

if [ -x "$HOME/.acme.sh/acme.sh" ]; then
    alias acme.sh='$HOME/.acme.sh/acme.sh'
fi

if [ -x "$(command -v keychain)" ]; then
    eval `keychain --eval --agents ssh id_rsa id_ed25519`
fi

export EDITOR=vim

alias ssh_with_pwd='ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -F /dev/null'
alias ssh_with_key='ssh -o IdentitiesOnly=yes -F /dev/null'
