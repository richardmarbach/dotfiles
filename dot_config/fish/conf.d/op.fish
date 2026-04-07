if type -q op
  set -l cache ~/.config/fish/completions/op.fish
  if not test -f $cache
    op completion fish > $cache
  end
end
