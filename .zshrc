# Linuxbrew default path
if [[ -d /home/linuxbrew/.linuxbrew/bin ]]; then
    export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
fi

# ------------------------------------------------
# OS detection
# ------------------------------------------------
OS="$(uname -s)"

# ------------------------------------------------
# Environment variables
# ------------------------------------------------
export XDG_CONFIG_HOME="$HOME/.config"
export HISTFILE="$HOME/.zhistory"
export SAVEHIST=1000
export HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_verify
export EDITOR="nvim"
ZSH="$HOME/.oh-my-zsh"
ZSH_TMUX_AUTOSTART=true
export PNPM_HOME="$HOME/Library/pnpm"
export NVIM_APPNAME=nvim
export GEM_HOME="$(ruby -e 'puts Gem.user_dir')"
export PATH="$PNPM_HOME:$GEM_HOME/bin:$PATH:/opt/homebrew/opt/openjdk/bin:$PATH"
export NEOVIDE_CONFIG="/Users/Zeb/dotfiles/.config/neovide/config.toml"
export EZA_CONFIG_DIR="/Users/Zeb/dotfiles/.config/eza/"
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional

# ------------------------------------------------
# Homebrew / Linuxbrew paths
# ------------------------------------------------
if command -v brew >/dev/null 2>&1; then
    # Determine prefix
    HOMEBREW_PREFIX=$(brew --prefix)

    # Add brew paths first so brew-installed tools take priority
    path=(
        "$HOMEBREW_PREFIX/bin"
        "$HOMEBREW_PREFIX/sbin"
        "$HOMEBREW_PREFIX/opt/curl/bin"
        "$HOMEBREW_PREFIX/opt/openjdk/bin"
        "$HOMEBREW_PREFIX/share/zsh-autosuggestions"
        "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting"
        "$HOMEBREW_PREFIX/share/powerlevel10k"
        $path…  # keep existing path after
    )

    # Export for all shells
    export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$HOMEBREW_PREFIX/opt/curl/bin:$HOMEBREW_PREFIX/opt/openjdk/bin:$PATH"
fi
# ------------------------------------------------
# Welcome banner
# ------------------------------------------------
if command -v figlet >/dev/null && command -v lolcat >/dev/null; then
    figlet "Welcome, $USER" | lolcat
    echo
    command -v pfetch >/dev/null && pfetch | lolcat
    command -v stormy >/dev/null && stormy | lolcat
    if command -v fortune >/dev/null && command -v cowsay >/dev/null; then
        fortune | cowsay -r | lolcat
    fi
    echo
fi

# ------------------------------------------------
# Oh My Zsh
# ------------------------------------------------
ZSH="$HOME/.oh-my-zsh"
plugins=(
    git tmux zoxide zsh-navigation-tools zsh-interactive-cd
    sudo vi-mode
)
source "$ZSH/oh-my-zsh.sh" > /dev/null 2>&1

# ------------------------------------------------
# Powerlevel10k
# ------------------------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
[[ -f "$HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme" ]] && \
    source "$HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme"
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ------------------------------------------------
# Completion
# ------------------------------------------------
autoload -Uz compinit
compinit

if command -v brew >/dev/null 2>&1; then
    FPATH="$HOMEBREW_PREFIX/share/zsh-completions:$FPATH"
fi

# ------------------------------------------------
# Syntax highlighting & autosuggestions
# ------------------------------------------------
[[ -f "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -f "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
    source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=blue,bold,underline"

# ------------------------------------------------
# Atuin history
# ------------------------------------------------
export ATUIN_NOBIND="true"
eval "$(atuin init zsh)"
bindkey '^x' atuin-search
bindkey '^[[A' atuin-up-search
bindkey '^[OA' atuin-up-search

# ------------------------------------------------
# fzf
# ------------------------------------------------
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
eval "$(fzf --zsh)"

# ------------------------------------------------
# zoxide
# ------------------------------------------------
eval "$(zoxide init zsh)"

# ------------------------------------------------
# Misc tool integrations
# ------------------------------------------------
command -v batman >/dev/null && eval "$(batman --export-env)"
command -v thefuck >/dev/null && eval "$(thefuck --alias fk)"
#command -v pipx >/dev/null && eval "$(register-python-argcomplete pipx)"
command -v carapace >/dev/null && source <(carapace _carapace)

# ------------------------------------------------
# Aliases
# ------------------------------------------------
alias c='clear'
alias ac='cd && clear'
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
alias tg='topgrade'
alias src='source ~/.zshrc'
alias i2p='open http://127.0.01:7657 && ssh -NL 7657:localhost:7657 zeb@192.168.1.191'
alias freenet='open http://127.0.0.1:7509 && ssh -NL 7509:localhost:7509 zeb@192.168.1.191'
alias ac='cd && clear'
alias af='anifetch -ff example.mp4'
alias lc='lazydocker'
alias lssh='lazyssh'

# ------------------------------------------------
# Functions
# ------------------------------------------------
spf() {
    local lastdir
    if [[ "$OS" == "Linux" ]]; then
        lastdir="${XDG_STATE_HOME:-$HOME/.local/state}/superfile/lastdir"
    else
        lastdir="$HOME/Library/Application Support/superfile/lastdir"
    fi

    command spf "$@"

    [[ -f "$lastdir" ]] && { . "$lastdir"; rm -f "$lastdir"; }
}

# ------------------------------------------------
# Completion styling
# ------------------------------------------------
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
zstyle ':completion:*:git:*' group-order 'main commands' 'alias commands' 'external commands'

# ------------------------------------------------
# Misc settings
# ------------------------------------------------
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="mm/dd/yyyy"
export PF_INFO="ascii title os host kernel uptime pkgs memory"

eval $(thefuck --alias)

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

