autoload -U colors && colors
autoload -Uz vcs_info
autoload -U add-zsh-hook
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' unstagedstr '*'
zstyle ':vcs_info:*' stagedstr '+'
zstyle ':vcs_info:git:*' formats ' %F{blue}(%b%u%c)'
setopt PROMPT_SUBST

PS1='%B%{$fg[green]%}%~%b${vcs_info_msg_0_} %(?.%{$fg[green]%}>.%{$fg[red]%}x)%{$reset_color%} '
if [[ -n "$SSH_CONNECTION" ]]; then
  REMOTE_ICON=" 󰑔 "
  PS1='%B%{$fg[green]%}󰑔 %~%b${vcs_info_msg_0_} %(?.%{$fg[green]%}>.%{$fg[red]%}x)%{$reset_color%} '
fi

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
TPM_PATH="${HOME}/.tmux/plugins/tpm"

if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

if [ ! -d "$TPM_PATH" ]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_PATH"
fi

source "$HOME/.config/zsh/zsh-syntax-highligting-theme.sh"

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

autoload -Uz compinit
compinit -C

zinit cdreplay -q

bindkey '^y' autosuggest-accept
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

bindkey -s '^f' '~/.local/scripts/tmux-sessionizer\n'

bindkey -v

function zle-keymap-select() {
  case $KEYMAP in
    vicmd) echo -ne '\e[2 q' ;;
    viins|main) echo -ne '\e[6 q' ;;
  esac
}
zle -N zle-keymap-select

zle-line-init() {
  zle -K viins
  echo -ne "\e[6 q"
}
zle -N zle-line-init

echo -ne '\e[6 q'

precmd() {
  local last_status=$?
  echo -ne '\e[6 q'
  vcs_info
  return $last_status
}

eval "$(fzf --zsh)"

autoload edit-command-line
zle -N edit-command-line

HISTSIZE=5000
HISTFILE=~/.cache/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

export EDITOR="nvim"
export PATH="$PATH:$HOME/.local/bin:$HOME/.local/scripts:$HOME/.local/python-scripts:$HOME/.screenlayout"
export KEYTIMEOUT=1
export XDG_DATA_DIRS="$XDG_DATA_DIRS:/usr/share:/usr/local/share:/var/lib/flatpak/exports/share:/home/riley/.local/share/flatpak/exports/share"

alias mpr="python manage.py runserver"
alias mpmm="python manage.py makemigrations"
alias mpm="python manage.py migrate"
alias mp="python manage.py"
alias zso="source ~/.zshrc"
alias psh='source "$(poetry env info --path)"/bin/activate'

alias be='bundle exec'
alias ber='bundle exec rails'
alias bers='bundle exec rails s'

alias dcb='docker compose build'
alias dcud='docker compose up -d'
alias dcd='docker compose down'
alias dclf='docker compose logs -f'

alias fd='cd $(find * -type d | fzf)'
alias fh='cd ~ && cd $(find * -type d -maxdepth 2 | fzf)'

alias gst='git status'
alias gaa='git add .'
alias gcmsg='git commit -m'
alias gp='git push'
alias gpsup='git push --set-upstream origin $(git branch --show-current)'
alias gl='git pull'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcm='git checkout $(git_main_branch)'

alias l='ls -lah --color'

alias k='kubectl'
alias ka='kubectl apply -f'
alias kar='kubectl apply --recursive -f'

alias n='nvim'

alias upd='update-arch'

alias ap='ansible-playbook'

alias s7='system76-power'

alias tss='sudo tailscale switch'

alias ghd='gh-dash'

alias oc='opencode'
alias ocp='opencode --agent plan'
alias och='opencode --agent haskell-dev --prompt "This project has some compile errors. Please help me fix them."'

alias ndr='nix-direnv-reload'

alias mwb='make ghciwatch static_ls=1 2>&1 | tee .devel-logs/ghciwatch-output'

export PATH="$PATH:$HOME/.cargo/bin"

[ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env"
export PATH="$HOME/.cabal/bin:$HOME/.ghcup/bin:$PATH"

export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

if command -v fnm >/dev/null; then
  eval "$(fnm env --use-on-cd)"
fi

eval "$(wt config shell init zsh)"

export PYENV_ROOT="${PYENV_ROOT:=${HOME}/.pyenv}"
if ! type pyenv > /dev/null && [ -f "${PYENV_ROOT}/bin/pyenv" ]; then
  export PATH="${PYENV_ROOT}/bin:${PATH}"
fi

if type pyenv > /dev/null; then
  export PATH="${PYENV_ROOT}/bin:${PYENV_ROOT}/shims:${PATH}"
  function pyenv() {
    unset -f pyenv
    eval "$(command pyenv init -)"
    if [[ -n "${ZSH_PYENV_LAZY_VIRTUALENV}" ]]; then
      eval "$(command pyenv virtualenv-init -)"
    fi
    pyenv "$@"
  }
fi

if command -v rbenv > /dev/null; then
  eval "$(rbenv init - zsh)"
fi

[ -f "/home/rileymathews/.ghcup/env" ] && . "/home/rileymathews/.ghcup/env"

eval "$(direnv hook zsh)"

export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

git_main_branch() {
  if git branch --list | grep -q "main"; then
    echo "main"
  else
    echo "master"
  fi
}

gacp() {
  git add .
  git status
  echo -n "continue? (y/n): "
  read response
  if [ "$response" = "y" ]; then
    echo -n "Enter commit message: "
    read message
    git commit -m "$(git symbolic-ref --short HEAD) -- $message"
    git push
  else
    git restore --staged .
  fi
}

for f in "$HOME/.local/shell"/*(N); do
  [[ -r "$f" && -f "$f" ]] && source "$f"
done

hyprlog() {
  echo "copying the last hyprland log to home dir as hyprland.log"
  cp /run/user/1000/hypr/$(command ls -t /run/user/1000/hypr/ | head -n 1)/hyprland.log ~/hyprland.log
}

[ -f "$HOME/.local/secrets" ] && source "$HOME/.local/secrets"

COMPUTER_NAME=$(cat /etc/hostname)

if [[ "$TERM" == "linux" ]] && [[ -z "$DISPLAY" ]] && [[ "$(tty)" == "/dev/tty1" ]]; then
  start-hyprland
fi
