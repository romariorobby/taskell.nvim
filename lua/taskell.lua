local api = vim.api
local win, buf
local M = {}

local function validate(path)
  if vim.fn.executable("taskell") == 0 then
    api.nvim_err_writeln("taskell binary is not installed. Please Install with your Package Manager")
    api.nvim_err_writeln("taskell is not installed. Call :TaskellInstall to install it")
    return
  end

  -- trim and get the full path
  path = string.gsub(path, "%s+", "")
  path = string.gsub(path, "\"", "")
  path = path == "" and "%" or path
  path = vim.fn.expand(path)
  path = vim.fn.fnamemodify(path, ":p")
  -- check if file exists
  local ok, _, code = os.rename(path, path)
  if not ok then
    if code == 13 then
      -- Permission denied, but it exists
      return path
    end
    api.nvim_err_writeln("file does not exists")
    return
  end

  local ext = vim.fn.fnamemodify(path, ":e")
  if ext ~= "md" then
    api.nvim_err_writeln("Taskell only support markdown files")
    return
  end

  return path
end

local function on_exit(job_id, code, event)
	if code == 0 then
		vim.cmd("silent! :q")
	end
	-- Reload on exit
	vim.cmd("silent :e!")
end


-- TODO: Build from source?
local function call_install_script()
  local script = [[
	if [ -f "/etc/arch-release" -a -f "/etc/artix-release" ];then
	  pacman --noconfirm taskell || exit 1
	elif [ "$(uname)" == "Darwin" ];then
	  brew install taskell || echo "Brew Not installed"; exit 1
      echo "Glow installed sucessfully!"
	else
	  echo "`:TaskellInstall` not support for this machine. Please Install manually."
	fi
  ]]
  vim.cmd("new")
  local shell = vim.o.shell
  vim.o.shell = '/bin/bash'
  vim.fn.termopen("set -e\n" .. script)
  vim.o.shell = shell
  vim.cmd("startinsert")
end

function M.close_window()
	api.nvim_win_close(win, true)
end

function M.create_commands()
  vim.cmd("command! -nargs=? Taskell :lua require('taskell').taskell('<f-args>')")
  vim.cmd("command! TaskellInstall :lua require('taskell').download_taskell()")
end

function M.download_taskell()
  if vim.fn.executable("taskell") == 1 then
    local answer = vim.fn.input(
                     "taskell already installed, do you want update? Y/n = ")
    answer = string.lower(answer)
    while answer ~= "y" and answer ~= "n" do
      answer = vim.fn.input("please answer Y or n = ")
      answer = string.lower(answer)
    end

    if answer == "n" then
      api.nvim_out_write("\n")
      return
    end
    api.nvim_out_write("updating taskell..\n")
  else
    print("installing taskell..")
  end
  call_install_script()
end

local function exec_taskell_command(cmd)
  vim.fn.termopen(cmd, { on_exit = on_exit })
end

local function open_window(path)

  -- window size
  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")
  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  -- BORDERS
  local border_buf = api.nvim_create_buf(false, true)
  local title = vim.fn.fnamemodify(path, ":.")
  local border_opts = {
    style = "minimal",
    relative = "editor",
    row = row - 1,
    col = col - 1,
    width = win_width + 2,
    height = win_height + 2,
  }
  local topleft, topright, botleft, botright = '╭', '╮', '╰', '╯'
  local border_lines = { topleft .. title .. string.rep('─', win_width - #title) .. topright }

  local middle_line = '│' .. string.rep(' ', win_width) .. '│'
  for _ = 1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, botleft .. string.rep('─', win_width) .. botright)

  -- Set border_lines in the border buffer
  api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

  -- Create border window
  local border_win = api.nvim_open_win(border_buf, true, border_opts)
  vim.cmd('set winblend=1')
  vim.cmd('set winhl=Normal:Floating')
  vim.cmd('setl nocursorcolumn')

  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
  }

  -- create preview buffer and set local options
  buf = api.nvim_create_buf(false, true)
  win = api.nvim_open_win(buf, true, opts)
  api.nvim_command("au BufWipeout <buffer> exe 'silent bwipeout! '" .. border_buf)
  api.nvim_buf_set_keymap(buf, "n", "q", ":lua require('taskell').close_window()<cr>",
                          {noremap = true, silent = true})
  vim.cmd("startinsert") -- Automatically Insert on taskell

  -- set local options
  api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  api.nvim_win_set_option(win, "winblend", 0)
  local cmd = (string.format("taskell %s", vim.fn.shellescape(path)))
  exec_taskell_command(cmd)
end

function M.taskell(file)
  local current_win = vim.fn.win_getid()
  if current_win == win then
    M.close_window()
  else
    local path = validate(file)
    if path == nil then
      return
    end
    open_window(path)
  end
end

return M
