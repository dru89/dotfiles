-- ==================== GENERAL CONFIG ========================
-- Core vim options

local opt = vim.opt

-- ==================== NVM NODE PATH =========================
-- Ensure nvm-managed Node is available for LSP servers
-- (nvm isn't initialized in non-interactive shells that Neovim spawns)
local function setup_nvm_node_path()
  if vim.fn.has("win32") == 1 then return end
  local handle = io.popen("bash -c 'source ~/.nvm/nvm.sh && dirname $(nvm which default)' 2>/dev/null")
  if handle then
    local result = handle:read("*a"):gsub("%s+$", "")
    handle:close()
    if result ~= "" and vim.fn.isdirectory(result) == 1 then
      vim.env.PATH = result .. ":" .. vim.env.PATH
    end
  end
end

setup_nvm_node_path()

-- ====================== WINDOWS COMPILER =======================
-- Tell tree-sitter and other build tools to use gcc instead of cl.exe
if vim.fn.has("win32") == 1 then
  vim.env.CC = "gcc"
end

-- General settings
opt.autoread = true                 -- Automatically reload a file when it's changed
opt.backspace = "indent,eol,start"  -- Make backspace work normally in insert mode
opt.history = 1000                  -- Lots of command history
opt.laststatus = 3                  -- Global statusline (neovim 0.7+)
opt.mouse = "a"                     -- Enable mouse in all modes
opt.relativenumber = true           -- Relative line numbers
opt.number = true                   -- Show current line number
opt.shortmess:append("I")           -- Don't show intro message
opt.showcmd = true                  -- Show incomplete commands
opt.showmode = false                -- Don't show mode (statusline will show it)
opt.visualbell = true               -- No sounds
opt.termguicolors = true            -- True color support

-- Hide buffers instead of killing them
opt.hidden = true

-- Allow cursor positioning in block mode
opt.virtualedit = "block"

-- Format options
opt.formatoptions:append("j")       -- Remove comment leaders when joining lines
opt.formatoptions:append("1")       -- Don't break after one-letter word

-- Disable cursor blinking
opt.guicursor = "a:blinkon0"

-- Disable legacy syntax system (Treesitter handles syntax highlighting)
vim.g.do_syntax_autocmds = 0

-- ==================== SWAP FILES =======================
-- Disable swap files and backups
opt.swapfile = false
opt.backup = false
opt.writebackup = false

-- ==================== PERSISTENT UNDO ========================
local undodir = vim.fn.stdpath("config") .. "/backups"
opt.undofile = true
opt.undodir = undodir

-- Create backups directory if it doesn't exist
vim.fn.mkdir(undodir, "p")

-- ==================== INDENTATION ===========================
opt.autoindent = true
opt.smartindent = true
opt.smarttab = true
opt.shiftwidth = 2
opt.softtabstop = 2
opt.tabstop = 2
opt.expandtab = true

-- Display tabs and trailing spaces visually
opt.list = true
opt.listchars = { tab = "  ", trail = "·" }

-- Line wrapping
opt.wrap = false                    -- Don't wrap lines
opt.linebreak = true                -- Wrap at convenient points
opt.textwidth = 120                 -- Max width of text

-- ==================== FOLDS =============================
opt.foldmethod = "expr"             -- Use treesitter for folding
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldnestmax = 3                 -- Only fold to third level
opt.foldenable = false              -- Don't turn on folding by default

-- =================== COMPLETION ==========================
opt.wildmode = "list:longest"
opt.wildmenu = true
opt.wildignore = {
  "*.o", "*.obj", "*~",
  "*vim/backups*",
  "*sass-cache*",
  "*DS_Store*",
  "vendor/rails/**",
  "vendor/cache/**",
  "*.gem",
  "log/**",
  "tmp/**",
  "*.png", "*.jpg", "*.gif",
  "node_modules/**",
  ".git/**"
}

-- =============== SCROLLING ===================
opt.scrolloff = 5
opt.sidescrolloff = 10
opt.sidescroll = 1

-- =============== SEARCH ==================
opt.incsearch = true
opt.hlsearch = true
opt.ignorecase = true
opt.smartcase = true

-- =============== SPLITS ==================
opt.splitright = true               -- Vertical splits go to the right
opt.splitbelow = true               -- Horizontal splits go below

-- =============== PERFORMANCE ==================
opt.updatetime = 250                -- Faster completion (default is 4000ms)
opt.timeoutlen = 300                -- Time to wait for mapped sequence
