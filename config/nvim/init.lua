vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = false
vim.opt.list = false
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wrap = false
vim.opt.scrolloff = 8

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to below window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to above window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

vim.keymap.set("n", "<leader>sq", "<cmd>nohlsearch<cr>", { desc = "Clear search highlighting" })

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    config = function()
      require("rose-pine").setup({
        styles = {
          bold = true,
          italic = false,
          transparency = false,
        },
        groups = {
          border = "muted",
          link = "iris",
          panel = "surface",
          headings = {
            h1 = "iris",
            h2 = "foam",
            h3 = "rose",
            h4 = "gold",
            h5 = "pine",
            h6 = "foam",
          },
        },
      })

      vim.cmd.colorscheme("rose-pine-moon")

      local type_hl = vim.api.nvim_get_hl(0, { name = "@type" })
      type_hl.bold = true
      vim.api.nvim_set_hl(0, "@type", type_hl)

      -- Plain text for links (no underline / no special link color)
      local plain_link = { link = "Normal", underline = false, sp = "none" }
      for _, group in ipairs({
        "@markup.link",
        "@markup.link.url",
        "@markup.underline",
        "@text.underline",
        "@text.uri",
        "@string.special.url",
      }) do
        vim.api.nvim_set_hl(0, group, plain_link)
      end
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup({})

      local parser_for_ft = {
        bash = "bash",
        sh = "bash",
        zsh = "bash",
        css = "css",
        scss = "css",
        dockerfile = "dockerfile",
        go = "go",
        html = "html",
        javascript = "javascript",
        javascriptreact = "javascript",
        json = "json",
        jsonc = "json",
        lua = "lua",
        markdown = "markdown",
        python = "python",
        rust = "rust",
        sql = "sql",
        toml = "toml",
        typescript = "typescript",
        typescriptreact = "tsx",
        tsx = "tsx",
        vim = "vim",
        help = "vimdoc",
        yaml = "yaml",
      }

      local installed_parsers = {}

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(event)
          local parser = parser_for_ft[vim.bo[event.buf].filetype]
          if parser and not installed_parsers[parser] then
            installed_parsers[parser] = true
            pcall(ts.install, parser)
          end
          pcall(vim.treesitter.start, event.buf)
        end,
      })
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { preview_width = 0.55 },
      },
      pickers = {
        find_files = { previewer = true },
        live_grep = { previewer = true },
      },
    },
    keys = {
      { "<leader>sf", function() require("telescope.builtin").find_files() end, desc = "Search files" },
      { "<leader>sg", function() require("telescope.builtin").live_grep() end, desc = "Search by grep" },
      { "<leader>sw", function() require("telescope.builtin").grep_string() end, desc = "Search current word" },
      { "<leader>sd", function() require("telescope.builtin").diagnostics() end, desc = "Search diagnostics" },
      { "<leader>sr", function() require("telescope.builtin").resume() end, desc = "Search resume" },
      { "<leader>sb", function() require("telescope.builtin").buffers() end, desc = "Search buffers" },
      { "<leader>sh", function() require("telescope.builtin").help_tags() end, desc = "Search help" },
      { "<leader>so", function() require("telescope.builtin").oldfiles() end, desc = "Search old files" },
      { "<leader>sk", function() require("telescope.builtin").keymaps() end, desc = "Search keymaps" },
      { "<leader>gs", function() require("telescope.builtin").git_status() end, desc = "Git status (modified files)" },
      { "<leader>gc", function() require("telescope.builtin").git_commits() end, desc = "Git commits" },
      { "<leader>gb", function() require("telescope.builtin").git_branches() end, desc = "Git branches" },
    },
  },
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },
      { "<leader>o", "<cmd>NvimTreeFindFile<cr>", desc = "Reveal file in tree" },
    },
    opts = {
      hijack_cursor = true,
      sync_root_with_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = true,
      },
      view = {
        width = 36,
        preserve_window_proportions = true,
      },
      renderer = {
        root_folder_label = false,
        indent_markers = { enable = true },
      },
      filters = {
        dotfiles = false,
      },
      git = {
        ignore = false,
      },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local opts = function(desc) return { buffer = bufnr, silent = true, desc = desc } end

        vim.keymap.set("n", "]h", gs.next_hunk, opts("Next hunk"))
        vim.keymap.set("n", "[h", gs.prev_hunk, opts("Previous hunk"))
        vim.keymap.set("n", "<leader>hp", gs.preview_hunk, opts("Preview hunk"))
        vim.keymap.set("n", "<leader>hr", gs.reset_hunk, opts("Reset hunk"))
        vim.keymap.set("n", "<leader>hd", gs.diffthis, opts("Diff against index"))
        vim.keymap.set("n", "<leader>hD", function() gs.diffthis("~") end, opts("Diff against last commit"))
        vim.keymap.set("n", "<leader>hb", function() gs.blame_line({ full = true }) end, opts("Blame line"))
      end,
    },
  },
  {
    "vim-test/vim-test",
    keys = {
      { "<leader>tt", "<cmd>TestNearest<cr>", desc = "Run nearest test" },
      { "<leader>tf", "<cmd>TestFile<cr>", desc = "Run file tests" },
      { "<leader>ts", "<cmd>TestSuite<cr>", desc = "Run test suite" },
      { "<leader>tl", "<cmd>TestLast<cr>", desc = "Run last test" },
    },
  },
  {
    "kdheepak/lazygit.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
    },
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    keys = {
      { "s", function() require("flash").jump() end, mode = { "n", "x", "o" }, desc = "Flash jump" },
      { "S", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash treesitter" },
    },
    opts = {},
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "rose-pine",
        section_separators = "",
        component_separators = "|",
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "diagnostics", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true, lsp_format = "never" })
        end,
        desc = "Format buffer",
      },
    },
    opts = {
      notify_on_error = true,
      format_on_save = function(bufnr)
        if vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].modifiable then
          return
        end
        return { timeout_ms = 5000, lsp_format = "never" }
      end,
      formatters_by_ft = {
        go = { "goimports", "gofmt" },
        rust = { "rustfmt" },
        python = { "ruff_fix", "ruff_format", stop_after_first = false },
        javascript = { "prettierd", "prettier", "eslint_d", stop_after_first = false },
        typescript = { "prettierd", "prettier", "eslint_d", stop_after_first = false },
        javascriptreact = { "prettierd", "prettier", "eslint_d", stop_after_first = false },
        typescriptreact = { "prettierd", "prettier", "eslint_d", stop_after_first = false },
        tsx = { "prettierd", "prettier", "eslint_d", stop_after_first = false },
        html = { "prettierd", "prettier", stop_after_first = true },
        css = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        yaml = { "prettierd", "prettier", stop_after_first = true },
        sql = { "sqlfluff" },
      },
    },
  },
  -- SQL client (Dadbod) + UI for easy DB connections (e.g. to dockerized postgres)
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    keys = {
      { "<leader>db", "<cmd>DBUIToggle<cr>", desc = "Toggle Database UI (SQL client)" },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_win_position = "left"
      vim.g.db_ui_tmp_query_location = "/tmp/dadbod_queries"
    end,
  },
  -- Popular for Go development
  {
    "olexsmir/gopher.nvim",
    ft = { "go", "gomod", "gowork", "gotmpl" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("gopher").setup({
        commands = {
          go = "go",
          gomodifytags = "gomodifytags",
          impl = "impl",
        },
      })
    end,
    keys = {
      { "<leader>gsj", "<cmd>GoTagAdd json<cr>", desc = "Add json struct tags (Go)" },
      { "<leader>gsy", "<cmd>GoTagAdd yaml<cr>", desc = "Add yaml struct tags (Go)" },
      { "<leader>gse", "<cmd>GoIfErr<cr>", desc = "Add if err (Go)" },
    },
  },
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = true,
      },
    },
    config = function(_, opts)
      require("nvim-ts-autotag").setup(opts)
    end,
  },
  -- Better diagnostics / trouble list (popular)
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
    },
  },
  {
    "saghen/blink.cmp",
    version = "1.*",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = { preset = "enter" },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        documentation = { auto_show = true },
        menu = { border = "rounded" },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      fuzzy = { implementation = "prefer_rust" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "saghen/blink.cmp",
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      local pad_h, pad_v = 2, 1

      local orig_open = vim.lsp.util.open_floating_preview
      vim.lsp.util.open_floating_preview = function(contents, syntax, opts, ...)
        opts = vim.tbl_deep_extend("force", opts or {}, {
          border = "rounded",
          max_width = math.floor(vim.o.columns * 0.6),
          max_height = math.floor(vim.o.lines * 0.4),
          wrap = true,
        })

        local padded = {}
        local padding = string.rep(" ", pad_h)
        for _ = 1, pad_v do
          padded[#padded + 1] = ""
        end
        for _, line in ipairs(contents) do
          padded[#padded + 1] = padding .. line .. padding
        end
        for _ = 1, pad_v do
          padded[#padded + 1] = ""
        end

        local buf, win = orig_open(padded, syntax, opts, ...)
        if win and vim.api.nvim_win_is_valid(win) then
          vim.wo[win].linebreak = true
          vim.wo[win].breakindent = true
          vim.wo[win].conceallevel = 2
          vim.wo[win].concealcursor = "niv"
        end
        return buf, win
      end

      vim.diagnostic.config({
        signs = false,
        virtual_text = false,
        virtual_lines = false,
        underline = false,
        update_in_insert = false,
        float = {
          border = "rounded",
          max_width = math.floor(vim.o.columns * 0.6),
          focusable = false,
          scope = "cursor",
        },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local opts = { buffer = event.buf, silent = true }
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client then
            client.server_capabilities.semanticTokensProvider = nil
          end

          vim.lsp.inlay_hint.enable(false, { bufnr = event.buf })

          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "gI", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        end,
      })

      -- All LSPs are pre-installed via Mason during the Docker image build
      local servers = {
        "lua_ls",
        "ts_ls",
        "eslint",
        "gopls",
        "bashls",
        "pyright",
        "rust_analyzer",
        "html",
        "cssls",
        "jsonls",
      }

      require("mason").setup({
        max_concurrent_installers = 2,
      })
      require("mason-lspconfig").setup({
        ensure_installed = servers,
        automatic_enable = false,
      })

      local capabilities = require("blink.cmp").get_lsp_capabilities()
      local server_settings = {
        eslint = {
          settings = {
            workingDirectory = { mode = "auto" },
          },
        },
        ts_ls = {
          settings = {
            typescript = { format = { enable = false } },
            javascript = { format = { enable = false } },
          },
        },
      }
      local server_bins = {
        lua_ls = "lua-language-server",
        bashls = "bash-language-server",
        gopls = "gopls",
        pyright = "pyright-langserver",
        rust_analyzer = "rust-analyzer",
        ts_ls = "typescript-language-server",
        eslint = "vscode-eslint-language-server",
        html = "vscode-html-language-server",
        cssls = "vscode-css-language-server",
        jsonls = "vscode-json-language-server",
      }

      local function try_enable_server(server)
        local bin = server_bins[server]
        if bin and vim.fn.executable(bin) == 0 then
          return
        end
        local cfg = vim.tbl_deep_extend("force", server_settings[server] or {}, {
          capabilities = capabilities,
        })
        if pcall(vim.lsp.config, server, cfg) then
          pcall(vim.lsp.enable, server)
        end
      end

      for _, server in ipairs(servers) do
        try_enable_server(server)
      end

      -- Enable LSPs as Mason finishes installing them (no warnings while downloading)
      vim.api.nvim_create_autocmd("User", {
        pattern = "MasonInstallCompleted",
        callback = function()
          for _, server in ipairs(servers) do
            try_enable_server(server)
          end
        end,
      })
    end,
  },
}, {
  checker = { enabled = true },
})
