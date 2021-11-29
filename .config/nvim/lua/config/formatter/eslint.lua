return {
  languages = {
    'javascript',
    'json',
    'jsonc',
    'svelte',
  },
  config = {
      function()
      return {
        exe = 'eslint',
        args = {'--fix', '--stdin', '--stdin-filename', '%:p'},
        stdin = true
      }
    end
  }
}
