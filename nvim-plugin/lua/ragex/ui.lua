-- UI components for ragex.nvim

local M = {}

-- Notification levels mapping
local levels = {
  debug = vim.log.levels.DEBUG,
  info = vim.log.levels.INFO,
  warn = vim.log.levels.WARN,
  error = vim.log.levels.ERROR,
}

-- Show notification
function M.notify(msg, level)
  level = levels[level] or vim.log.levels.INFO
  vim.notify("[Ragex] " .. msg, level)
end

-- Show loading notification
function M.notify_loading(msg)
  return vim.notify("[Ragex] " .. msg, vim.log.levels.INFO, {
    timeout = false,
    hide_from_history = true,
  })
end

-- Dismiss notification
function M.dismiss_notification(notif)
  if notif then
    vim.notify("", vim.log.levels.INFO, { replace = notif, timeout = 1 })
  end
end

-- Create floating window
function M.create_float(opts)
  opts = opts or {}
  
  local width = opts.width or math.floor(vim.o.columns * 0.8)
  local height = opts.height or math.floor(vim.o.lines * 0.8)
  
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  local buf = vim.api.nvim_create_buf(false, true)
  
  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = opts.border or "rounded",
    title = opts.title,
    title_pos = "center",
  }
  
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", opts.filetype or "ragex")
  
  -- Set window options
  vim.api.nvim_win_set_option(win, "wrap", opts.wrap or false)
  vim.api.nvim_win_set_option(win, "cursorline", true)
  
  -- Add close keymaps
  local close = function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
  
  return buf, win
end

-- Show text in floating window
function M.show_float(lines, opts)
  opts = opts or {}
  
  local buf, win = M.create_float(opts)
  
  -- Set lines
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Make buffer read-only
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  
  return buf, win
end

-- Format table as aligned columns
function M.format_table(rows, headers)
  if #rows == 0 then
    return {}
  end
  
  -- Calculate column widths
  local widths = {}
  for i, header in ipairs(headers) do
    widths[i] = #header
  end
  
  for _, row in ipairs(rows) do
    for i, cell in ipairs(row) do
      widths[i] = math.max(widths[i] or 0, #tostring(cell))
    end
  end
  
  -- Format lines
  local lines = {}
  
  -- Header
  local header_parts = {}
  for i, header in ipairs(headers) do
    table.insert(header_parts, string.format("%-" .. widths[i] .. "s", header))
  end
  table.insert(lines, table.concat(header_parts, " | "))
  
  -- Separator
  local sep_parts = {}
  for i = 1, #headers do
    table.insert(sep_parts, string.rep("-", widths[i]))
  end
  table.insert(lines, table.concat(sep_parts, "-+-"))
  
  -- Rows
  for _, row in ipairs(rows) do
    local row_parts = {}
    for i, cell in ipairs(row) do
      table.insert(row_parts, string.format("%-" .. widths[i] .. "s", tostring(cell)))
    end
    table.insert(lines, table.concat(row_parts, " | "))
  end
  
  return lines
end

-- Show progress bar (simple text-based)
function M.show_progress(current, total, message)
  local width = 40
  local filled = math.floor((current / total) * width)
  local empty = width - filled
  
  local bar = "[" .. string.rep("=", filled) .. string.rep(" ", empty) .. "]"
  local percent = string.format("%3d%%", math.floor((current / total) * 100))
  local msg = string.format("%s %s %s (%d/%d)", message or "Progress", bar, percent, current, total)
  
  M.notify(msg, "info")
end

-- Show results in floating window with formatting
function M.show_results(results, opts)
  opts = opts or {}
  
  if not results or #results == 0 then
    M.notify("No results found", "warn")
    return
  end
  
  local lines = {}
  
  if opts.title then
    table.insert(lines, opts.title)
    table.insert(lines, string.rep("=", #opts.title))
    table.insert(lines, "")
  end
  
  for i, result in ipairs(results) do
    if opts.formatter then
      local formatted = opts.formatter(result, i)
      if type(formatted) == "table" then
        vim.list_extend(lines, formatted)
      else
        table.insert(lines, formatted)
      end
    else
      table.insert(lines, vim.inspect(result))
    end
    
    if i < #results then
      table.insert(lines, "")
    end
  end
  
  M.show_float(lines, {
    title = opts.title or "Results",
    height = opts.height,
    width = opts.width,
    filetype = opts.filetype,
  })
end

-- Input prompt with validation
function M.input(prompt, opts, callback)
  opts = opts or {}
  
  vim.ui.input({
    prompt = prompt,
    default = opts.default,
  }, function(input)
    if not input or input == "" then
      if callback then
        callback(nil)
      end
      return
    end
    
    if opts.validate then
      local valid, err = opts.validate(input)
      if not valid then
        M.notify(err or "Invalid input", "error")
        if callback then
          callback(nil)
        end
        return
      end
    end
    
    if callback then
      callback(input)
    end
  end)
end

-- Select from list
function M.select(items, opts, callback)
  opts = opts or {}
  
  vim.ui.select(items, {
    prompt = opts.prompt or "Select:",
    format_item = opts.format_item,
  }, callback)
end

-- Confirm dialog
function M.confirm(message, callback)
  vim.ui.select({ "Yes", "No" }, {
    prompt = message,
  }, function(choice)
    if callback then
      callback(choice == "Yes")
    end
  end)
end

return M
