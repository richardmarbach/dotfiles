export PATH="$HOME/bin:$PATH"

export FZF_DEFAULT_COMMAND='rg --files --hidden'

if [[ uname == "Darwin" ]]; then
  source /usr/local/opt/asdf/asdf.sh
  source /usr/local/opt/asdf/etc/bash_completion.d/asdf.bash
fi
