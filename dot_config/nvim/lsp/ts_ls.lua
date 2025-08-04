return {
  -- cmd = { "mise x bun@latest -- bunx --bun typescript-language-server --stdio" },
  cmd = { "mise", "x", "bun@latest", "--", "bunx", "--bun", "typescript-language-server", "--stdio" },
  filetypes = { "typescript" },
}
