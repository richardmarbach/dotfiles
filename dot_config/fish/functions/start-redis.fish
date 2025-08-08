function start-redis --wraps='docker container run -d --rm -it --name redis -p "127.0.0.1:6379:6379" -d redis:6.2.3-alpine redis-server --appendonly yes' --description 'alias start-redis=docker container run -d --rm -it --name redis -p "127.0.0.1:6379:6379" -d redis:6.2.3-alpine redis-server --appendonly yes'
  docker container run -d --rm -it --name redis -p "127.0.0.1:6379:6379" -d redis:8-alpine redis-server --appendonly yes $argv; 
end
