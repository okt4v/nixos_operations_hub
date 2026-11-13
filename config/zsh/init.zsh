export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$HOME/.local/share/go/bin"

export EDITOR=nvim
export VISUAL=nvim
export TERMINAL=kitty
export BROWSER=zen-beta
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"
export WLR_RENDERER=vulkan
export SAL_USE_VCLPLUGIN=gtk3

bindkey -v
export KEYTIMEOUT=1

echo "Welcome back ${USER}!"

# History: large, shared between shells, no duplicates, nothing that starts
# with a space.
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt AUTO_PUSHD PUSHD_IGNORE_DUPS INTERACTIVE_COMMENTS

# Prompt:  path  branch(* unstaged, + staged)  env (inside a devshell)
#          duration (when a command took 5s or more);  ❯ turns red on failure
autoload -Uz vcs_info add-zsh-hook
zmodload zsh/datetime
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' stagedstr '+'
zstyle ':vcs_info:git:*' formats ' %F{magenta} %b%F{yellow}%u%c%f'
zstyle ':vcs_info:git:*' actionformats ' %F{magenta} %b%F{red}|%a%f'

_hub_preexec() { _hub_t0=$EPOCHSECONDS }
_hub_precmd() {
  vcs_info
  _hub_took=
  if [[ -n $_hub_t0 ]]; then
    local d=$(( EPOCHSECONDS - _hub_t0 ))
    (( d >= 5 )) && _hub_took=" %F{yellow}${d}s%f"
    unset _hub_t0
  fi
  _hub_env=
  [[ -n $IN_NIX_SHELL || -n $DIRENV_DIR ]] && _hub_env=' %F{cyan}env%f'
  print -P "%F{240}${(pl:$COLUMNS::─:)}%f"
}
add-zsh-hook preexec _hub_preexec
add-zsh-hook precmd _hub_precmd

setopt PROMPT_SUBST
PROMPT='%F{blue}%~%f${vcs_info_msg_0_}${_hub_env}${_hub_took}
%(?.❯.%F{red}❯%f) '

autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
bindkey -M viins '^F' autosuggest-accept

# `v` in normal mode: edit the command line in nvim
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

# hub <Tab> completes recipe names
_hub() { local -a recipes; recipes=(${=$(hub --summary 2>/dev/null)}); compadd -a recipes }
compdef _hub hub


# `cd` is zoxide: a real directory is entered directly (errors shown),
# anything else is matched against visited directories.
eval "$(zoxide init zsh --cmd cd)"
eval "$(fzf --zsh)"
# Ctrl-R: atuin history (per-directory first). After fzf so it wins the binding.
eval "$(atuin init zsh --disable-up-arrow)"

