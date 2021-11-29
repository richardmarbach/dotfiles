local filetypes = {
  "javascript",
  "javascriptreact",
  "javascript.jsx",
  "typescript",
  "typescriptreact",
  "typescript.tsx",
  "vue",
  "svelte",
}

vim.cmd [[autocmd BufWritePre *.ts,*.tsx,*.js,*.jsx,*.vue,*.svelte EslintFixAll]]
-- for _, filetype in ipairs(filetypes) do
--   vim.cmd 'autocmd FileType ' .. filetype .. ' nnoremap <buffer> <space>= <cmd>EslintFixAll<cr>'
-- end
  
return {
  filetypes = filetypes,
}
