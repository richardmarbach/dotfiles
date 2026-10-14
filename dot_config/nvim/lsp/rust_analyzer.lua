-- An explicit sysroot stops nvim-lspconfig's root_dir from blocking on
-- `rustc --print sysroot` (~400ms via rustup) for every Rust buffer opened.
-- "discover" is rust-analyzer's own default, so server behavior is unchanged.
return {
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        sysroot = "discover",
      },
    },
  },
}
