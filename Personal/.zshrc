alias kb="xset r rate 130 100"
alias aws='ssh -i ~/.ssh/aws-puffy.pem ubuntu@3.131.93.39'

# Created by `pipx` on 2026-04-11 23:03:27
export PATH="$PATH:/home/jellyjam/.local/bin"
export LC_ALL=en_US.UTF-8


# ── Pure prompt ────────────────────────────────────────────
fpath+=($HOME/.zsh/pure)
autoload -U promptinit; promptinit
prompt pure

# Pure color tweaks to match Nord
zstyle :prompt:pure:prompt:success color '#88C0D0'
zstyle :prompt:pure:prompt:error   color '#BF616A'
zstyle :prompt:pure:git:branch     color '#81A1C1'
zstyle :prompt:pure:path           color '#D8DEE9'

# ── Autosuggestions ────────────────────────────────────────

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#4C566A'   # Nord3 — subtle grey hint
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ── Syntax highlighting (load LAST, always) ────────────────



source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# ── Editor ─────────────────────────────────────────────────
export EDITOR=nvim
export VISUAL=nvim

# ── Completion ─────────────────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Nord shell colors
export LS_COLORS="di=34:ln=36:so=35:pi=33:ex=32:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Nord less/man colors
export LESS_TERMCAP_mb=$'\e[1;34m'
export LESS_TERMCAP_md=$'\e[1;34m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[1;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;36m'
