function viaeurope
  set env $argv[1]
  set -q env || set -l env 'production'

  heroku run VIA_USER=$VIA_USER STATEMENT_TIMEOUT=0 RAILS_LOG_LEVEL=debug bin/rails console -a viaeurope-$env
end
