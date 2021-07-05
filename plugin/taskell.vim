" prevent loading file twice
if exists("g:loaded_taskell")
  finish
endif

lua require("taskell").create_commands()

let g:loaded_taskell = 1
