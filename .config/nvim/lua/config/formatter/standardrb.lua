return {
  languages = {'ruby'},
  config = {
      function()
      return {
        exe = 'standardrb',
        args = {'--fix', '--stdin', '%:p', '2>/dev/null', '|', "awk 'f; /^====================$/{f=1}'"},
        stdin = true
      }
    end
  }
}
