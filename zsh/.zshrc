# ================================================================
# ZSH CONFIGURATION
# macOS Apple Silicon | Ghostty | Oh My Zsh | Powerlevel10k
# ================================================================

# ------------------------------------------------
# Powerlevel10k Instant Prompt
# Must be near the beginning of .zshrc.
# Keep initialization below free of console output when possible.
# ------------------------------------------------

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# ------------------------------------------------
# Environment
# ------------------------------------------------

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export EDITOR="nvim"
export VISUAL="nvim"
export NVIM_APPNAME="nvim"

export NEOVIDE_CONFIG="$HOME/dotfiles/.config/neovide/config.toml"
export EZA_CONFIG_DIR="$HOME/dotfiles/.config/eza/"

export PF_INFO="ascii title os host kernel uptime pkgs memory"

# Apple Silicon Homebrew
export HOMEBREW_PREFIX="/opt/homebrew"

# Ruby gems: retain the existing behavior without running Ruby
# on every shell startup. This is the conventional user gem path.
export GEM_HOME="$HOME/.local/share/gem/ruby/$(ruby -e 'print RUBY_VERSION' 2>/dev/null | cut -d. -f1-2)"

# If the computed Ruby directory does not exist, RubyGems can still
# use its default configuration. Review GEM_HOME if using mise Ruby.


# ------------------------------------------------
# PATH
# ------------------------------------------------

# Keep PATH unique while preserving ordering.
typeset -U path PATH

path=(
    "$HOMEBREW_PREFIX/bin"
    "$HOMEBREW_PREFIX/sbin"
    "$HOMEBREW_PREFIX/opt/curl/bin"
    "$HOMEBREW_PREFIX/opt/openjdk/bin"
    "$HOME/Library/pnpm"
    "$HOME/.lmstudio/bin"
    "$HOME/.local/bin"
    "$HOME/.hermes/bin"
    "$HOME/.local/lib/python3.14/site-packages"
    $path
)

export PATH


# ------------------------------------------------
# History
# ------------------------------------------------

HISTFILE="$HOME/.zhistory"
HISTSIZE=10000
SAVEHIST=10000

setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_VERIFY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

# ------------------------------------------------
# Editing and completion behavior
# ------------------------------------------------

bindkey -v

# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"

ZSH_TMUX_AUTOSTART=false
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="mm/dd/yyyy"


# ------------------------------------------------
# Oh My Zsh plugins
# ------------------------------------------------

plugins=(
    tmux
    zoxide
    zsh-navigation-tools
    zsh-interactive-cd
    sudo
    vi-mode
)

source "$ZSH/oh-my-zsh.sh"


# ------------------------------------------------
# Powerlevel10k
# ------------------------------------------------

if [[ -r "$HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
    source "$HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme"
fi

[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"


# ------------------------------------------------
# Completion
# ------------------------------------------------

# Add Homebrew completions before initializing completion.
fpath=(
    "$HOMEBREW_PREFIX/share/zsh-completions"
    $fpath
)

# Oh My Zsh initializes completion. Do not run compinit twice.

# Completion colors
zstyle ':completion:*' list-colors \
    'ma=48;5;24;38;5;255' \
    'di=38;5;117' \
    'ln=38;5;213' \
    'ex=38;5;159' \
    'fi=38;5;189'

zstyle ':completion:*' menu select
zstyle ':completion:*' list-prompt '%S%M matches%s'
zstyle ':completion:*' select-prompt '%S%p%s'
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git:*' group-order \
    'main commands' \
    'alias commands' \
    'external commands'

# Let fzf-tab control the completion menu.
zstyle ':completion:*' menu no

# Apply LS_COLORS when available.
if [[ -n "$LS_COLORS" ]]; then
    zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
fi

# Carapace completions.
export CARAPACE_BRIDGES='zsh,fish,bash,inshells'

if (( $+commands[carapace] )); then
    source <(carapace _carapace)
fi

# fzf-tab must load after completion initialization and before
# syntax highlighting.
if [[ -r "$HOMEBREW_PREFIX/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh" ]]; then
    source "$HOMEBREW_PREFIX/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh"
fi

zstyle ':fzf-tab:*' fzf-flags \
    --color=fg:#a9b1d6,bg:#1a1b26,hl:#7aa2f7 \
    --color=fg+:#c0caf5,bg+:#24283b,hl+:#7dcfff \
    --color=info:#e0af68,prompt:#bb9af7,pointer:#f7768e \
    --color=marker:#9ece6a,spinner:#7dcfff,header:#565f89

zstyle ':fzf-tab:complete:cd:*' fzf-preview \
    'eza -1 --color=always $realpath'


# ------------------------------------------------
# Syntax highlighting and autosuggestions
# ------------------------------------------------

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=blue,bold,underline"

# Autosuggestions
if [[ -r "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Fast syntax highlighting
# Check the installed formula for the correct filename.
if [[ -r "$HOMEBREW_PREFIX/opt/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]]; then
    source "$HOMEBREW_PREFIX/opt/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
elif [[ -r "$HOMEBREW_PREFIX/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]]; then
    source "$HOMEBREW_PREFIX/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
fi


# ------------------------------------------------
# Atuin history
# ------------------------------------------------

if (( $+commands[atuin] )); then
    eval "$(atuin init zsh)"
fi


# ------------------------------------------------
# fzf
# ------------------------------------------------

export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'

export FZF_DEFAULT_OPTS="--preview='bat --color=always --style=numbers --line-range=:500 -- {}' --preview-window='right:60%:wrap'"

if (( $+commands[fzf] )); then
    eval "$(fzf --zsh)"
fi


# ------------------------------------------------
# Zoxide
# ------------------------------------------------

# The Oh My Zsh zoxide plugin may already initialize zoxide.
# Do not initialize it again here unless you remove that plugin.
# eval "$(zoxide init zsh)"


# ------------------------------------------------
# Misc tool integrations
# ------------------------------------------------

# The Fuck
if (( $+commands[thefuck] )); then
    eval "$(thefuck --alias fk)"
fi

# Batman man-page integration
if (( $+commands[batman] )); then
    eval "$(batman --export-env)"
fi

# Forgit
if [[ -r "$HOMEBREW_PREFIX/share/forgit/forgit.plugin.zsh" ]]; then
    source "$HOMEBREW_PREFIX/share/forgit/forgit.plugin.zsh"
fi


# ------------------------------------------------
# OpenCode environment
# ------------------------------------------------

if [[ -r "$HOME/dotfiles/opencode/opencode.env" ]]; then
    set -a
    source "$HOME/dotfiles/opencode/opencode.env"
    set +a
fi


# ------------------------------------------------
# Mise
# ------------------------------------------------

if (( $+commands[mise] )); then
    eval "$(mise activate zsh)"
fi


# ------------------------------------------------
# Broot
# ------------------------------------------------

# This is the Bash launcher from your original configuration.
# Retained for compatibility with your existing setup.
if [[ -r "$HOME/.config/broot/launcher/bash/br" ]]; then
    source "$HOME/.config/broot/launcher/bash/br"
fi


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

alias ls='eza --long --color=always --icons=always --all --git --git-repos'
alias lst='eza --long --color=always --icons=always --all --git --git-repos --tree'

alias fvim='~/.config/scripts/fzf_listoldfiles.sh'
alias ovim='~/.config/scripts/zoxide_openfiles_nvim.sh'

alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

alias lg='lazygit'
alias ld='lazydocker'
alias lsh='lazyssh'
alias tg='topgrade'

alias src='source ~/.zshrc'

alias gc='git commit'
alias gp='git push'


# ------------------------------------------------
# Functions
# ------------------------------------------------

# Superfile with last-directory restoration.
spf() {
    local lastdir

    if [[ "$OSTYPE" == linux* ]]; then
        lastdir="${XDG_STATE_HOME:-$HOME/.local/state}/superfile/lastdir"
    else
        lastdir="$HOME/Library/Application Support/superfile/lastdir"
    fi

    command spf "$@"

    if [[ -f "$lastdir" ]]; then
        source "$lastdir"
        command rm -f "$lastdir"
    fi
}

source /Users/Zeb/.config/broot/launcher/bash/br
