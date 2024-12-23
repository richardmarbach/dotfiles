function start-valkey --wraps='docker container run -d --rm -it --name valkey -p "127.0.0.1:6379:6379" -d valkey:8-alpine valkey --appendonly yes' --description 'alias start-valkey=docker container run -d --rm -it --name valkey -p "127.0.0.1:6379:6379" -d valkey:8-alpine valkey --appendonly yes'
  docker container run -d --rm -it --name valkey -p "127.0.0.1:6379:6379" -d valkey:8-alpine valkey --appendonly yes $argv; 
end
