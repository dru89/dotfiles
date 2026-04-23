-- ==================== KEYMAPS ====================
-- Custom keybindings

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Make Y act like D, C, etc.
keymap("n", "Y", "y$", opts)

-- Use 0 to go to beginning of code, ^ to go to beginning of line
keymap("n", "0", "^", opts)
keymap("n", "^", "0", opts)

-- j and k should move with word-wraps
keymap("n", "j", "gj", opts)
keymap("n", "k", "gk", opts)

-- "Open last file" mapped to Ctrl-e
keymap("n", "<C-e>", ":e#<CR>", opts)

-- =============== TOGGLES ==================
-- Toggle line numbers
keymap("n", "\\l", ":set number! relativenumber!<CR>", opts)
-- Toggle paste mode
keymap("n", "\\p", ":set paste!<CR>", opts)
-- Toggle quickfix and location lists
keymap("n", "\\q", function()
  local qf_exists = false
  for _, win in pairs(vim.fn.getwininfo()) do
    if win["quickfix"] == 1 then
      qf_exists = true
    end
  end
  if qf_exists then
    vim.cmd("cclose")
  else
    vim.cmd("copen")
  end
end, opts)

keymap("n", "\\w", function()
  local qf_exists = false
  for _, win in pairs(vim.fn.getwininfo()) do
    if win["loclist"] == 1 then
      qf_exists = true
    end
  end
  if qf_exists then
    vim.cmd("lclose")
  else
    vim.cmd("lopen")
  end
end, opts)

-- =============== QUICKFIX/LOCATION LIST NAVIGATION ==================
keymap("n", "<leader>cn", ":cnext<CR>", opts)
keymap("n", "<leader>cp", ":cprevious<CR>", opts)
keymap("n", "<leader>cc", ":cc<CR>", opts)
keymap("n", "<leader>ln", ":lnext<CR>", opts)
keymap("n", "<leader>lp", ":lprevious<CR>", opts)
keymap("n", "<leader>ll", ":ll<CR>", opts)

-- =============== BUFFER NAVIGATION ==================
keymap("n", "<leader>z", ":bprevious<CR>", opts)
keymap("n", "<leader>x", ":bnext<CR>", opts)

-- =============== INSERT MODE ==================
-- jk for <ESC>
keymap("i", "jk", "<Esc>", opts)
-- Alt-Backspace to delete previous word (vim's default <C-w> behavior)
keymap("i", "<M-BS>", "<C-w>", opts)
keymap("c", "jk", "<C-c>", opts)

-- =============== SPLIT NAVIGATION ==================
-- Move through splits
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- =============== TERMINAL MODE MAPPINGS ==================
-- Use <Esc> to exit terminal mode
keymap("t", "<Esc>", "<C-\\><C-n>", opts)
-- Navigate splits from terminal mode
keymap("t", "<C-h>", "<C-\\><C-n><C-w>h", opts)
keymap("t", "<C-j>", "<C-\\><C-n><C-w>j", opts)
keymap("t", "<C-k>", "<C-\\><C-n><C-w>k", opts)
keymap("t", "<C-l>", "<C-\\><C-n><C-w>l", opts)

-- =============== FILE EXPLORER ==================
-- Will be overridden by plugin-specific keymaps
keymap("n", "\\e", ":Explore<CR>", opts)

-- =============== BETTER INDENTING ==================
-- Stay in visual mode when indenting
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- =============== CLEAR SEARCH HIGHLIGHT ==================
keymap("n", "<Esc>", ":noh<CR>", opts)
