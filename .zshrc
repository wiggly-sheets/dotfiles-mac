
# startup commands welcome message
figlet "welcome," $USER | lolcat && echo && pfetch | lolcat && echo && stormy | lolcat && echo && fortune | cowsay -r | lolcat;

#-----------------------------
# Instant prompt (Powerlevel10k) for fast startup
# -----------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# -----------------------------
# Environment variables & tools
# -----------------------------
ZSH="$HOME/.oh-my-zsh"
ZSH_TMUX_AUTOSTART=true
export PNPM_HOME="$HOME/Library/pnpm"
export NVIM_APPNAME=nvim
export GEM_HOME="$(ruby -e 'puts Gem.user_dir')"
export PATH="$PNPM_HOME:$GEM_HOME/bin:$PATH:/opt/homebrew/opt/openjdk/bin:$PATH"
export XDG_CONFIG_HOME="$HOME/.config"

# -----------------------------
# Oh My Zsh
# -----------------------------
plugins=(git tmux aliases alias-finder brew common-aliases copybuffer copyfile copypath cp gh macos ssh sudo tldr vi-mode zsh-navigation-tools zoxide zbell zsh-interactive-cd xcode)
source "$ZSH/oh-my-zsh.sh" > /dev/null 2>&1

# -----------------------------
# Powerlevel10k
# -----------------------------
source $HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# -----------------------------
# Editor
# -----------------------------
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='nvim'
fi

# -----------------------------
# pnpm already in PATH
# -----------------------------
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# -----------------------------
# Syntax highlighting & autosuggestions
# -----------------------------
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
 
if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

    autoload -Uz compinit
    compinit
  fi

bindkey '^ ' autosuggest-execute

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=blue,bold,underline"

# -----------------------------
# History setup
# -----------------------------
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_verify

# -----------------------------
# Aliases & command overrides
# -----------------------------
alias c='clear'
alias nv='nvim'
alias vim='nvim'
alias ff='fastfetch -c all'
alias top='btop'
alias cd='z'
alias cat='bat'
alias ls='eza --long --color=always --icons=always --all'
alias lstree='eza --long --color=always --icons=always --all --tree'
alias lsgit='eza --long --color=always --icons=always --tree --all --git --git-repos'
alias fvim='~/.config/scripts/fzf_listoldfiles.sh'
alias ovim="~/.config/scripts/zoxide_openfiles_nvim.sh"
alias fman="compgen -c | fzf | xargs man"
alias kk='nvim $(fzf --preview="bat --color=always {}")'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias lg='lazygit'
alias up='topgrade'
alias i2p='open http://127.0.01:7657 && ssh -NL 7657:localhost:7657 zeb@192.168.1.191'
alias ac='cd && clear'
alias af='anifetch -ff example.mp4'
alias tg='topgrade'
alias src='source ~/.zshrc'
# -----------------------------
# fzf defaults & functions
# -----------------------------
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
#export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
#export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
  --color=fg:#d0d0d0,fg+:#d0d0d0,,bg:-1,bg+:#262626
  --color=hl:#5f87af,hl+:#5fd7ff,info:#afaf87,marker:#87ff00
  --color=prompt:#d7005f,spinner:#af5fff,pointer:#af5fff,header:#87afaf
  --color=border:#262626,label:#aeaeae,query:#d9d9d9
  --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="> "
  --marker=">" --pointer="◆" --separator="─" --scrollbar="│"
  --preview "bat --style=numbers --color=always --line-range :500 {}"
  '

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

_fzf_compgen_path() { fd --hidden --exclude .git . "$1" }
_fzf_compgen_dir()  { fd --type=d --hidden --exclude .git . "$1" }

_fzf_comprun() {
  local command=$1
  shift
  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo ${}'" "$@" ;;
    ssh)          fzf --preview 'dig {}' "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

eval "$(fzf --zsh)"
eval "$(batman --export-env)"
eval "$(thefuck --alias)"
eval "$(thefuck --alias fk)"
eval "$(zoxide init zsh)"
eval "$(register-python-argcomplete pipx)"
source ~/.config/scripts/fzf-git.sh


# -----------------------------
# Other settings
# -----------------------------
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="mm/dd/yyyy"

# Optional: faster fd preview instead of fzf default
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

spf() {
    os=$(uname -s)

    # Linux
    if [[ "$os" == "Linux" ]]; then
        export SPF_LAST_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/superfile/lastdir"
    fi

    # macOS
    if [[ "$os" == "Darwin" ]]; then
        export SPF_LAST_DIR="$HOME/Library/Application Support/superfile/lastdir"
    fi

    command spf "$@"

    [ ! -f "$SPF_LAST_DIR" ] || {
        . "$SPF_LAST_DIR"
        rm -f -- "$SPF_LAST_DIR" > /dev/null
    }
}

# Created by `pipx` on 2025-09-21 19:29:37
export PATH="$PATH:/Users/Zeb/.local/bin"

export NEOVIDE_CONFIG="/Users/Zeb/dotfiles/.config/neovide/config.toml"
export EZA_CONFIG_DIR="/Users/Zeb/dotfiles/.config/eza/"

export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
source <(carapace _carapace)
zstyle ':completion:*:git:*' group-order 'main commands' 'alias commands' 'external commands'

export PATH="/opt/homebrew/opt/curl/bin:$PATH"

# The following lines were added by compinstall

zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle :compinstall filename '/Users/Zeb/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/Zeb/.lmstudio/bin"
# End of LM Studio CLI section

export PF_INFO="ascii title os host kernel uptime pkgs memory"



# atuin
export ATUIN_NOBIND="true"
eval "$(atuin init zsh)"
bindkey '^x' atuin-search
# bind to the up key, which depends on terminal mode
bindkey '^[[A' atuin-up-search
bindkey '^[OA' atuin-up-search


