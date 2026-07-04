# devenv — Portable Docker Developer Environment

A batteries-included Docker image that gives you a consistent, modern developer environment anywhere Docker runs.

## What's included (latest versions at build time)

- **Neovim** (newest) — preconfigured with your personal `~/.config/nvim`
- **Go** (newest)
- **Node.js** (newest)
- **Python** (newest)
- **TypeScript** 7.0 (falls back to latest)
- **SQL client**:
  - `usql` (universal SQL client — postgres, mysql, sqlite, etc.)
  - `psql` (PostgreSQL client)
  - **Neovim SQL client**: vim-dadbod + dadbod-ui (`<leader>db`)
- **Linters / Formatters**:
  - Go: goimports, gofmt, golangci-lint
  - Web/TS/JS: prettier + prettierd + eslint
  - Python: ruff, black, isort
  - SQL: sqlfluff
- **Popular plugins** pre-added for Go + Web/TypeScript frontend:
  - `gopher.nvim` (Go struct tags, iferr, etc.)
  - `nvim-ts-autotag` (auto close/rename HTML/JSX/TSX tags)
  - `trouble.nvim` (beautiful diagnostics & symbol list)
  - Treesitter for Go, TS/TSX, JS, HTML, CSS, SQL, etc.
  - Full LSP (gopls, ts_ls, eslint, pyright, html, cssls, jsonls...)
  - conform for formatting
  - blink.cmp, telescope, nvim-tree, gitsigns, lazygit, flash, etc.

## Quick Start (Mac + Docker Desktop)

1. **Clone and build** (run once, or when you want fresh latest versions):

   ```bash
   git clone https://github.com/latzskim/devenv.git ~/Documents/Projects/devenv
   cd ~/Documents/Projects/devenv
   docker build -t devenv:latest .
   cp .env.example .env   # only needed if you use docker-compose db
   ```

2. **Open any local repository** in the dev environment:

   ```bash
   cd ~/Documents/Projects/your-awesome-project
   # Option A: use the helper (recommended)
   ~/Documents/Projects/devenv/bin/dev

   # Option B: one-liner
   docker run --rm -it \
     -v "$(pwd):/workspace" \
     -w /workspace \
     devenv:latest zsh
   ```

   Inside the container you are in `/workspace` (your project) with full tools + your Neovim config ready.

   **Web dev servers** (`npm run dev`, Vite, etc.): the `dev` script publishes common ports (3000, 5173, …) to your Mac, so `http://localhost:3000` in your browser reaches the server running *inside* the container. Without port publishing, `localhost` on your Mac is a different machine than `localhost` inside Docker. Busy ports on your Mac are skipped automatically (macOS often uses 5000 for AirPlay). Override with `DEVENV_PORTS="3000 5173"`.

   **Multiple terminal windows**: run `dev` again while a session is already open — it attaches to the same container (shared files, dev servers, and ports). No second container, no duplicate port binding.

   **Next.js / Turbopack in Docker**: always run `npm install` and `npm run dev` *inside* devenv, not on your Mac. If the page refresh-loops with Turbopack panics, delete the cache (`rm -rf .next`) and restart `npm run dev` in the container. The `dev` script stores `.next` in a Docker volume so Mac and container caches do not mix.

   - `nvim .` or just `nvim`
   - `go version`, `node --version`, `python --version`
   - `lg` → lazygit
   - `<leader>db` → SQL database UI

3. **Make `dev` globally available** (optional but very convenient):

   ```bash
   mkdir -p ~/bin
   ln -s ~/Documents/Projects/devenv/bin/dev ~/bin/dev
   # Make sure ~/bin is in your PATH (usually in .zshrc)
   export PATH="$HOME/bin:$PATH"
   ```

   Now from **any** folder on your Mac:

   ```bash
   dev
   dev nvim
   dev --build          # rebuild image + enter
   ```

## Connecting to other Docker containers (e.g. Postgres)

### Easiest on macOS (Docker Desktop)

If you run a DB with published ports:

```bash
docker run -d --name pg -e POSTGRES_PASSWORD=your-local-password -p 5432:5432 postgres
```

Inside the dev container use:

- Neovim: `:DBUI` → Add connection → `postgresql://postgres:your-local-password@host.docker.internal:5432/postgres`
- Terminal: `usql 'postgresql://postgres:your-local-password@host.docker.internal:5432/postgres'`
- `psql -h host.docker.internal -U postgres`

`host.docker.internal` is the magic hostname that reaches the Mac host (and published ports).

### Using docker networks (works everywhere)

```bash
docker network create devnet

docker run -d --network devnet --name mypg \
  -e POSTGRES_PASSWORD=your-local-password postgres

# Then launch dev on same network
docker run --rm -it --network devnet \
  -v "$(pwd):/workspace" -w /workspace \
  devenv:latest
```

Connect string: `postgresql://postgres:your-local-password@mypg:5432/postgres`

### Using the provided docker-compose (recommended for projects)

```bash
# From inside your project folder
docker compose -f ~/Documents/Projects/devenv/docker-compose.yml up -d db
docker compose -f ~/Documents/Projects/devenv/docker-compose.yml run --rm dev
```

Inside: connect to `db:5432` with user `postgres` and the password from your `.env` file.

## Updating to newest versions

Simply rebuild:

```bash
docker build --no-cache -t devenv:latest .
```

Mise fetches the absolute latest of Neovim/Go/Node/Python on each build.

## Persisting state (optional)

Neovim plugins, Mason binaries, go modules cache, npm cache etc. are baked into the image.

If you want to persist additional state (history, extra global packages):

```bash
docker run --rm -it \
  -v "$(pwd):/workspace" \
  -v devenv-home:/home/dev \
  -w /workspace \
  devenv:latest
```

The helper script + compose file already set up some named volumes.

## Memory usage (important on macOS)

Activity Monitor's **"Docker Virtual Machine"** (~8 GB) is **not** your devenv container. On macOS, Docker Desktop runs a Linux VM and reserves memory for it (Settings → Resources → Memory).

Your actual `devenv` container typically uses **~100–300 MB** while idle. To reduce the VM footprint:

1. **Docker Desktop → Settings → Resources → Memory** → set to **2–4 GB** (enough for devenv + a dev server)
2. Stop unused containers: `docker container prune`
3. Rebuild after optimizations: `dev --build`

Treesitter parsers install on demand per file type; language servers are baked into the image at build time.

## npm defaults

The image ships with a global `~/.npmrc` setting:

```ini
min-release-age=30
```

This rejects registry versions published less than **30 days** ago (npm 11+ supply-chain hardening). Versions already pinned in `package-lock.json` still install normally. To override for one command: `npm install --force`.

Edit `config/npm/.npmrc` and rebuild to change the policy.

## Tips

- Your full Neovim config (including rose-pine, telescope keymaps, etc.) is baked in.
- All Mason LSPs used by the config are pre-installed during the Docker build.
- To edit your Neovim config live: either rebuild after changes to `config/nvim`, or temporarily mount:
  ```bash
  docker run ... -v "$HOME/.config/nvim:/home/dev/.config/nvim" ...
  ```
- Inside the container your user is `dev`.
- Exiting the shell removes the container by default (ephemeral + clean). Use `dev --no-rm` if you want to keep it around and `docker exec -it ... zsh`.

## Project layout

```
Dockerfile           # The main image definition
docker-compose.yml   # Example with postgres + volume setup
bin/dev              # Super convenient launcher for any folder
config/nvim/         # Your Neovim config (copied at build)
config/npm/.npmrc    # Global npm defaults (min-release-age, etc.)
README.md
```

Enjoy a consistent, powerful dev environment that travels with you anywhere Docker is available.
