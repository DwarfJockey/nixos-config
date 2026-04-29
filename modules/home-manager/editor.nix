{ inputs, ... }:

{
  imports = [ inputs.nixvim.homeModules.nixvim ];

  # ── Nixvim ─────────────────────────────────────────────────────────────────
  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    opts = {
      number         = true;
      relativenumber = true;
      signcolumn     = "yes";

      tabstop     = 2;
      shiftwidth  = 2;
      expandtab   = true;
      smartindent = true;

      wrap      = false;
      scrolloff = 8;

      updatetime  = 250;
      timeoutlen  = 300;

      splitright = true;
      splitbelow = true;

      undofile = true;

      autoread = true;

      hlsearch   = true;
      incsearch  = true;
      ignorecase = true;
      smartcase  = true;
    };

    globals.mapleader = " ";

    autoCmd = [
      {
        event = [ "FocusGained" "BufEnter" "CursorHold" "CursorHoldI" ];
        pattern = "*";
        command = "checktime";
      }
    ];

    keymaps = [
      # Clear search highlights
      { mode = "n"; key = "<Esc>";      action = "<cmd>nohlsearch<CR>"; }

      # Better window navigation
      { mode = "n"; key = "<C-h>";      action = "<C-w><C-h>"; }
      { mode = "n"; key = "<C-l>";      action = "<C-w><C-l>"; }
      { mode = "n"; key = "<C-j>";      action = "<C-w><C-j>"; }
      { mode = "n"; key = "<C-k>";      action = "<C-w><C-k>"; }

      # Move lines up/down in visual mode
      { mode = "v"; key = "J";          action = ":m '>+1<CR>gv=gv"; }
      { mode = "v"; key = "K";          action = ":m '<-2<CR>gv=gv"; }

      # Keep cursor centred when jumping
      { mode = "n"; key = "<C-d>";      action = "<C-d>zz"; }
      { mode = "n"; key = "<C-u>";      action = "<C-u>zz"; }
      { mode = "n"; key = "n";          action = "nzzzv"; }
      { mode = "n"; key = "N";          action = "Nzzzv"; }

      # Telescope
      { mode = "n"; key = "<leader>ff"; action = "<cmd>Telescope find_files<CR>"; }
      { mode = "n"; key = "<leader>fg"; action = "<cmd>Telescope live_grep<CR>"; }
      { mode = "n"; key = "<leader>fb"; action = "<cmd>Telescope buffers<CR>"; }
      { mode = "n"; key = "<leader>fh"; action = "<cmd>Telescope help_tags<CR>"; }
      { mode = "n"; key = "<leader>fs"; action = "<cmd>Telescope lsp_document_symbols<CR>"; }

      # File tree
      { mode = "n"; key = "<leader>e";  action = "<cmd>Neotree toggle<CR>"; }

      # LSP
      { mode = "n"; key = "gd";         action = "<cmd>lua vim.lsp.buf.definition()<CR>"; }
      { mode = "n"; key = "gr";         action = "<cmd>Telescope lsp_references<CR>"; }
      { mode = "n"; key = "K";          action = "<cmd>lua vim.lsp.buf.hover()<CR>"; }
      { mode = "n"; key = "<leader>rn"; action = "<cmd>lua vim.lsp.buf.rename()<CR>"; }
      { mode = "n"; key = "<leader>ca"; action = "<cmd>lua vim.lsp.buf.code_action()<CR>"; }
      { mode = "n"; key = "<leader>d";  action = "<cmd>lua vim.diagnostic.open_float()<CR>"; }
      { mode = "n"; key = "[d";         action = "<cmd>lua vim.diagnostic.goto_prev()<CR>"; }
      { mode = "n"; key = "]d";         action = "<cmd>lua vim.diagnostic.goto_next()<CR>"; }

      # Format
      { mode = "n"; key = "<leader>cf"; action = "<cmd>lua vim.lsp.buf.format()<CR>"; }
    ];

    plugins = {

      # ── Syntax highlighting ────────────────────────────────────────────────
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable     = true;
        };
      };

      # ── LSP ────────────────────────────────────────────────────────────────
      lsp = {
        enable = true;
        servers = {
          nixd.enable      = true;   # Nix
          lua_ls.enable    = true;   # Lua
          rust_analyzer = {          # Rust
            enable = true;
            installCargo  = false;
            installRustc  = false;
          };
          ts_ls.enable     = true;   # TypeScript / JavaScript
          pyright.enable   = true;   # Python
          bashls.enable    = true;   # Bash
        };
      };

      # ── Completion ─────────────────────────────────────────────────────────
      cmp = {
        enable = true;
        settings = {
          sources = [
            { name = "nvim_lsp"; }
            { name = "buffer"; }
            { name = "path"; }
            { name = "luasnip"; }
          ];
          mapping = {
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>"     = "cmp.mapping.abort()";
            "<CR>"      = "cmp.mapping.confirm({ select = true })";
            "<Tab>"     = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Tab>"   = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<C-d>"     = "cmp.mapping.scroll_docs(4)";
            "<C-u>"     = "cmp.mapping.scroll_docs(-4)";
          };
        };
      };

      luasnip.enable   = true;
      cmp_luasnip.enable = true;
      cmp-nvim-lsp.enable = true;
      cmp-buffer.enable   = true;
      cmp-path.enable     = true;

      # ── Fuzzy finder ───────────────────────────────────────────────────────
      telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
      };

      # Explicit to suppress deprecation warning
      web-devicons.enable = true;

      # ── File tree ──────────────────────────────────────────────────────────
      neo-tree = {
        enable = true;
        settings = {
          window.width = 30;
          filesystem.filtered_items.visible = true;
        };
      };

      # ── Git ────────────────────────────────────────────────────────────────
      gitsigns = {
        enable = true;
        settings.signs = {
          add.text          = "▎";
          change.text       = "▎";
          delete.text       = "";
          topdelete.text    = "";
          changedelete.text = "▎";
        };
      };

      lualine.enable          = true;
      which-key.enable        = true;
      nvim-autopairs.enable   = true;
      comment.enable          = true;
      indent-blankline.enable = true;
      fidget.enable           = true;
    };
  };
}
