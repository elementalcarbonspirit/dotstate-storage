# Set up the prompt
fpath+=("/home/jellyjam/.config/nvm/versions/node/v24.14.0/lib/node_modules/pure-prompt/functions")
autoload -Uz promptinit
promptinit
prompt pure

setopt histignorealldups sharehistory

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

# Use modern completion system
autoload -Uz compinit
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'
export PATH=$PATH:~/.local/bin
export PATH=$PATH:/home/linuxbrew/.linuxbrew/bin
xset r rate 150 50
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
eval "$(zoxide init zsh)"
#eval $(thefuck --alias)
export PATH="$PATH:/opt/nvim/bin"

export NVM_DIR="$HOME/.config/nvm"
nvm() {
  unset -f nvm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm "$@"
}  # This loads nvm bash_completion
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$PATH:$HOME/.dotnet
# Add Go binaries to PATH
export PATH="$PATH:$HOME/go/bin"
alias picom-toggle='if pgrep -x picom > /dev/null; then pkill picom && echo "picom off"; else picom --daemon && echo "picom on"; fi'




alias proxyon="gsettings set org.gnome.system.proxy mode 'manual' && \
  gsettings set org.gnome.system.proxy.http host '140.245.120.119' && \
  gsettings set org.gnome.system.proxy.http port 8443 && \
  gsettings set org.gnome.system.proxy.https host '140.245.120.119' && \
  gsettings set org.gnome.system.proxy.https port 8443 && \
  echo 'Proxy ON'"



  
alias proxyoff="gsettings set org.gnome.system.proxy mode 'none' && echo 'Proxy OFF'"
alias proxystatus="gsettings get org.gnome.system.proxy mode"




alias awson="gsettings set org.gnome.system.proxy mode 'manual' && \
  gsettings set org.gnome.system.proxy.http host '3.131.93.39' && \
  gsettings set org.gnome.system.proxy.http port 8443 && \
  gsettings set org.gnome.system.proxy.https host '3.131.93.39' && \
  gsettings set org.gnome.system.proxy.https port 8443 && \
  echo 'Proxy ON - AWS US'"

addproxy() {
  if [ -z "$1" ]; then
    echo "Usage: addproxy example.com"
    return 1
  fi
  ssh -i ~/.ssh/aws-proxy.pem ubuntu@3.131.93.39 "echo '  - '"'"'$1'"'"'' >> ~/.config/mihomo/ruleset/adult.yaml && sudo systemctl restart mihomo"
  echo "Added $1 and restarted mihomo"
}

alias oracle='ssh -i ~/.ssh/oracle2.key ubuntu@140.245.120.119'
