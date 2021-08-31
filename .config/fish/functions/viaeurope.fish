function viaeurope
  set env $argv[1]
  set -q env || set -l env 'production'

  heroku run RAILS_LOG_LEVEL=debug bin/rails console -a viaeurope-$env
end
