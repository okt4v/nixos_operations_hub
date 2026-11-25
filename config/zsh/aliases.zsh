alias v='nvim'
alias g='git'
alias lg='lazygit'
alias del='trash-put' # rm with an undo: trash-list, trash-restore
alias h='hub'
alias t='task'
alias nd='nix develop'
alias ls='lsd -l --git --group-directories-first --blocks permission,size,date,git,name'
alias la='lsd -lA --git --group-directories-first --blocks permission,size,date,git,name'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias copy='wl-copy'
alias p='python'
alias cat='bat'
alias va='source ./.venv/bin/activate'
alias vd='deactivate'
alias tfwr-saves="cd ~/.local/share/Steam/steamapps/compatdata/2060160/pfx/drive_c/users/steamuser/AppData/LocalLow/TheFarmerWasReplaced/TheFarmerWasReplaced/Saves"

# NixOS specific
alias nrs="nh os switch"
alias excalidraw-start="sudo systemctl start docker-excalidraw && echo 'Excalidraw: http://localhost:3002'"
alias excalidraw-stop="sudo systemctl stop docker-excalidraw"

# mkcd <dir>: create and enter
mkcd() { mkdir -p "$1" && builtin cd "$1" }

# x <archive>: extract whatever it is
x() {
  case $1 in
    *.tar.*|*.tgz|*.tbz2|*.txz|*.tar) tar xf "$1" ;;
    *.zip) unzip "$1" ;;
    *.7z) 7z x "$1" ;;
    *.gz) gunzip "$1" ;;
    *.xz) unxz "$1" ;;
    *.zst) unzstd "$1" ;;
    *) echo "x: don't know how to extract $1" >&2; return 1 ;;
  esac
}
