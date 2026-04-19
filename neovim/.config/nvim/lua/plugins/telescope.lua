-- ==================== TELESCOPE FUZZY FINDER ====================
-- Modern fuzzy finder with telescope.nvim
-- Replaces: fzf.vim, ack.vim

return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = vim.fn.has("win32")
      },
    },
    keys = {
      -- File finding
      { "<leader><leader>", function()
          local ok = pcall(require("telescope.builtin").git_files)
          if not ok then
            require("telescope.builtin").find_files()
          end
        end, desc = "Find files (git or all)" },
      { "<leader>t", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>b", "<cmd>Telescope buffers<cr>", desc = "Find buffers" },

      -- Search
      { "<leader>sg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>sw", "<cmd>Telescope grep_string<cr>", desc = "Grep word under cursor" },

      -- LSP
      { "<leader>ss", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
      { "<leader>sS", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Workspace symbols" },

      -- Other
      { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
      { "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
      { "<leader>sc", "<cmd>Telescope commands<cr>", desc = "Commands" },
      { "<leader>sr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")

      telescope.setup({
        defaults = {
          prompt_prefix = " ",
          selection_caret = " ",
          path_display = { "smart" },

          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
              ["<C-x>"] = actions.delete_buffer,
            },
            n = {
              ["q"] = actions.close,
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            },
          },

          file_ignore_patterns = {
            "node_modules",
            ".git/",
            "dist/",
            "build/",
            "target/",
            "vendor/",
          },
        },

        pickers = {
          find_files = {
            hidden = true,
          },
          buffers = {
            sort_mru = true,
            mappings = {
              i = {
                ["<C-d>"] = actions.delete_buffer,
              },
            },
          },
        },

        extensions = {
          fzf = vim.fn.has("win32") == 0 and {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          } or nil,
        },
      })

      -- Load extensions
      if vim.fn.has("win32") == 0 then
        telescope.load_extension("fzf")
      end
    end,
  },

  -- FZF native for better performance
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    cond = vim.fn.has("win32") == 0
  },
}
