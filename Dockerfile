# syntax=docker/dockerfile:1
# Dev environment Docker image
# Tools: Latest Neovim, Go, Node.js, Python, TypeScript 7 (or latest), SQL client + linters
# Pre-configured with your Neovim setup + popular Go + Web/TS plugins

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Base packages + build dependencies (for python/node builds if needed by tools)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    fd-find \
    fzf \
    git \
    gnupg \
    jq \
    libffi-dev \
    libpq-dev \
    libssl-dev \
    libyaml-dev \
    postgresql-client \
    ripgrep \
    sqlite3 \
    sudo \
    unzip \
    wget \
    xz-utils \
    zlib1g-dev \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Create non-root dev user (best practice)
RUN useradd -m -s /bin/zsh -U dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/dev && \
    chmod 0440 /etc/sudoers.d/dev

USER dev
WORKDIR /home/dev

ENV HOME=/home/dev
ENV PATH="/home/dev/.local/bin:/home/dev/.local/share/mise/shims:${PATH}"

# Install mise (tool version manager - handles latest versions cleanly)
RUN curl https://mise.run | sh

# Install latest versions of core tools via mise (always fresh at image build time)
RUN mise install -y \
    neovim@latest \
    go@latest \
    nodejs@latest \
    python@latest \
    lazygit@latest \
    usql@latest \
    starship@latest

# Set global tool versions
RUN mise use -g \
    neovim@latest \
    go@latest \
    nodejs@latest \
    python@latest \
    lazygit@latest \
    usql@latest \
    starship@latest

# Global Node CLIs for formatting/linting (LSPs come from Mason, not duplicated here)
# Note: prettierd package on npm is @fsouza/prettierd (provides the `prettierd` binary)
RUN mise exec -- npm install -g \
    prettier \
    @fsouza/prettierd \
    eslint

# Tailwind LSP is nice-to-have; don't fail the whole build if it has issues
RUN mise exec -- npm install -g @tailwindcss/language-server || true

# TypeScript - prefer the requested 7.0, gracefully fall back to latest
RUN mise exec -- npm install -g typescript@7.0 || mise exec -- npm install -g typescript@latest

# tree-sitter CLI is required by nvim-treesitter (main) to build some parsers (e.g. javascript, tsx, etc.)
RUN mise exec -- npm install -g tree-sitter-cli

# Go helpers for gopher.nvim (gopls itself is installed via Mason)
RUN mise exec -- sh -c '\
    mkdir -p "$HOME/.local/bin" && \
    GOBIN="$HOME/.local/bin" go install golang.org/x/tools/cmd/goimports@latest && \
    GOBIN="$HOME/.local/bin" go install github.com/fatih/gomodifytags@latest && \
    GOBIN="$HOME/.local/bin" go install github.com/josharian/impl@latest && \
    go clean -cache -modcache \
'

# Python tools (format/lint + sqlfluff for SQL)
RUN mise exec -- sh -c '\
    pip install --user --no-cache-dir \
      ruff \
      black \
      isort \
      sqlfluff \
'

# Copy Neovim configuration (your personal config + added Go/Web plugins)
COPY --chown=dev:dev config/nvim /home/dev/.config/nvim

# Pre-install Lazy plugins + core Mason LSPs (heavy/optional LSPs install on first use)
RUN nvim --headless -c 'Lazy! sync' -c 'qa!' || true
RUN nvim --headless \
    -c 'MasonInstall --force lua-language-server typescript-language-server eslint-lsp gopls' \
    -c 'qa!' || true

# Drop build caches — they bloat the image but aren't needed at runtime
RUN mise exec -- npm cache clean --force && \
    rm -rf \
      /home/dev/.cache/pip \
      /home/dev/.cache/mise/downloads \
      /home/dev/.cache/go-build \
      /tmp/*

# Shell configuration (zsh + starship + mise activation + sensible defaults)
RUN cat > ~/.zshrc << 'ZSHRC'
export LANG=C.UTF-8
export EDITOR=nvim
export VISUAL=nvim

# mise
eval "$(mise activate zsh)"

# Starship prompt
eval "$(starship init zsh)"

# Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Useful aliases
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# Quick dev helpers
alias lg='lazygit'
alias db='nvim +DBUI'

# Make sure local bins + mason + go tools are available
export PATH="$HOME/.local/share/nvim/mason/bin:$HOME/.local/bin:$PATH"

# History
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

ZSHRC

# Also provide a basic .bashrc for bash users
RUN cat > ~/.bashrc << 'BASHRC'
export LANG=C.UTF-8
export EDITOR=nvim
export VISUAL=nvim

eval "$(mise activate bash)"
eval "$(starship init bash)"

export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
export PATH="$HOME/.local/share/nvim/mason/bin:$HOME/.local/bin:$PATH"

alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias ..='cd ..'
alias lg='lazygit'
alias db='nvim +DBUI'

BASHRC

# Starship config (clean + informative)
RUN mkdir -p ~/.config && cat > ~/.config/starship.toml << 'STARSHIP'
format = """
$username\
$hostname\
$directory\
$git_branch\
$git_status\
$nodejs\
$golang\
$python\
$rust\
$docker_context\
$line_break\
$character"""

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✗](bold red)"

[directory]
truncation_length = 3
truncate_to_repo = true

[git_branch]
symbol = "🌱 "
truncation_length = 20

[git_status]
disabled = false

[nodejs]
symbol = "⬢ "
version_format = "${major}.${minor}"

[golang]
symbol = "🐹 "

[python]
symbol = "🐍 "

[rust]
symbol = "🦀 "

STARSHIP

# Default working directory for workspaces (mount your code here)
WORKDIR /workspace

# Default command
CMD ["zsh"]

# Helpful labels
LABEL org.opencontainers.image.title="devenv"
LABEL org.opencontainers.image.description="Portable developer environment: Neovim + Go + Node + Python + TS + SQL"
