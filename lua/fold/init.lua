local M = {}
M.buffers = {}

M.config = {
  -- Key used to start the fold "mode"
  enable = 'zz',
  -- Key used to toggle the folding of the fold under the cursor
  toggle = '<CR>',
  -- Lines of context on each side of the match
  context = 5,
  -- Number of trailing characters in the foldtext
  tail = 100,
}

local function is_in_fold()
  return vim.fn.foldlevel('.') > 0
end

local function is_in_open_fold()
  return is_in_fold() and vim.fn.foldclosed('.') == -1
end

local function restore_foldopts(buf, win)
  if not M.buffers[buf].defaults then
    return
  end

  local defaults = M.buffers[buf].defaults
  vim.api.nvim_win_set_option(win, 'foldmethod', defaults.foldmethod)
  vim.api.nvim_win_set_option(win, 'foldexpr',   defaults.foldexpr)
  vim.api.nvim_win_set_option(win, 'foldlevel',  defaults.foldlevel)
  vim.api.nvim_win_set_option(win, 'foldtext',   defaults.foldtext)
  M.buffers[buf].defaults = nil
end

local function store_foldopts(buf, win)
  local defaults = {}
  defaults.foldmethod = vim.api.nvim_win_get_option(win, 'foldmethod')
  defaults.foldexpr   = vim.api.nvim_win_get_option(win, 'foldexpr')
  defaults.foldlevel  = vim.api.nvim_win_get_option(win, 'foldlevel')
  defaults.foldtext   = vim.api.nvim_win_get_option(win, 'foldtext')

  if not M.buffers[buf] then
    M.buffers[buf] = {}
  end
  M.buffers[buf].defaults = defaults
end

function M.setup(opts)
  if opts and type(opts) ~= 'table' then
    error('[fold.nvim] Invalid parameter `opts` to `fold.setup(opts)`')
  end
  M.config = vim.tbl_extend('force', M.config, opts or {})

  vim.api.nvim_set_keymap(
    'n',
    M.config.enable,
    '<cmd>lua require("fold").toggle()<CR>',
    { silent = true, noremap = true }
  )
end

function M.stop()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  if not M.buffers[buf].active then
    return
  end

  restore_foldopts(buf, win)
  vim.api.nvim_buf_del_keymap(buf, 'n', M.config.toggle)
  vim.cmd([[
    augroup fold.nvim
      autocmd!
    augroup END
  ]])

  M.buffers[buf].active = false
end

function M.start()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  if not M.buffers[buf] then
    M.buffers[buf] = {}
  end
  if M.buffers[buf].active then
    return
  end

  store_foldopts(buf, win)
  vim.opt_local.foldmethod = 'expr'
  vim.opt_local.foldexpr = 'v:lua._FOLD.foldexpr()'
  vim.opt_local.foldtext = 'v:lua._FOLD.foldtext()'
  vim.opt_local.foldlevel = 0
  vim.api.nvim_buf_set_keymap(buf, 'n', M.config.toggle, '<cmd>lua require("fold").fold_or_unfold()<CR>', { silent = true, noremap = true })
  vim.cmd([[
    augroup fold.nvim
      autocmd!
      autocmd CursorMoved <buffer> lua require('fold').cursor_moved()
    augroup END
  ]])

  M.buffers[buf].active = true
end

function M.foldexpr()
  local lnum = vim.v.lnum - 1
  local line_last = vim.fn.line('$') - 1

  local line_start = lnum - M.config.context
  if line_start < 0 then
    line_start = 0
  end
  local line_end = lnum + M.config.context
  if line_end > line_last then
    line_end = line_last
  end
  local context = vim.api.nvim_buf_get_lines(0, line_start, line_end, false)

  local pattern = vim.fn.getreg('/')
  if M.config.smartcase and vim.regex('\\u'):match_str(pattern) then
    pattern = '\\C' .. pattern
  end

  return vim.fn.match(context, pattern) == -1 and 1 or 0
end

function M.foldtext()
  local foldstart = vim.v.foldstart
  local foldend = vim.v.foldend

  return string.format('%s/ %d - %d \\%s',
    string.rep('_', 3),
    tostring(foldstart),
    tostring(foldend),
    string.rep('_', M.config.tail)
  )
end

function M.toggle()
  local buf = vim.api.nvim_get_current_buf()
  if M.buffers[buf] and M.buffers[buf].active then
    M.stop()
  else
    M.start()
  end
end
---Open a created fold
function M.open()
  if is_in_fold() then
    vim.cmd('normal! zo')
  end
end

---Close a created fold
function M.close()
  if is_in_open_fold() then
    vim.cmd('normal! zc')
  end
end

---Function for the autocommands triggered from CursorMoved and CursorMovedI events
function M.cursor_moved()
  if is_in_open_fold() then
    M.open()
  else
    vim.api.nvim_win_set_option(0, 'foldlevel', 0)
  end
end

function M.fold_or_unfold()
  if is_in_open_fold() then
    M.close()
  elseif is_in_fold() then
    M.open()
  end
end

-- NOTE(mortepau): This is required due to &foldexpr and %foldtext expecting functions, which cannot be required from a lua module
_FOLD = _FOLD or {}
_FOLD.foldexpr = M.foldexpr
_FOLD.foldtext = M.foldtext
return M
