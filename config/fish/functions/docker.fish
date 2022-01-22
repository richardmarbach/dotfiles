if type -q podman
  function docker --wraps=podman --description 'alias docker=podman'
    podman $argv; 
  end
end
