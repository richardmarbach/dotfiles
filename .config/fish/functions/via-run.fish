function via-run
  set env $argv[1]
  set task $argv[2]

  heroku run:detached VIA_USER=$VIA_USER STATEMENT_TIMEOUT=0 RAILS_LOG_LEVEL=debug bin/rake oneoff:$task -a viaeurope-$env
end
