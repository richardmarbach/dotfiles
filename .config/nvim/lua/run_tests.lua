local api = vim.api
local fn = vim.fn
local cmd = vim.cmd

local function set_test_file(command_suffix)
  vim.t.my_test_file = fn.getreg('%') .. command_suffix
end

local function run_tests(filename)
  filename = filename or ""
  -- Write the file and run the tests for the given filename
  if fn.expand('%') ~= "" then
    cmd('w') 
  end

  if filename == "" then
    cmd('tabnew term://bin/test')
  else
    cmd('split term://bundle exec rspec --color ' .. filename)
  end
end

local function run_test_file(command_suffix)
  command_suffix = command_suffix or ""

  local in_test_file = string.match(fn.expand('%'), '.*_spec.rb')

  if in_test_file then
    set_test_file(command_suffix)
  elseif not vim.t.my_test_file then
    return
  end

  run_tests(vim.t.my_test_file)
end

local function run_nearest_test()
  local spec_line_number = fn.line('.')
  run_test_file(':' .. spec_line_number)
end


return {
    run_tests = run_tests,
    run_test_file = run_test_file,
    run_nearest_test = run_nearest_test,
    set_test_file = set_test_file
}
