set fish_greeting

eval "$(/opt/homebrew/bin/brew shellenv)"

if status is-interactive
    # Commands to run in interactive sessions can go here
end

if test (uname) = "Darwin"
  if test -d (brew --prefix)"/share/fish/completions"
      set -gx fish_complete_path $fish_complete_path (brew --prefix)/share/fish/completions
  end

  if test -d (brew --prefix)"/share/fish/vendor_completions.d"
      set -gx fish_complete_path $fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
  end
end

set fish_function_path $fish_function_path ~/.config/fish/plugins/plugin-foreign-env/functions

set -x -g RIPGREP_CONFIG_PATH ~/.config/rg/config
set -x -g FZF_DEFAULT_COMMAND "rg --files --hidden"
set -x -g EDITOR "nvim"
set -x -g GEM_EDITOR "nvim"
set -x -g MANPAGER "nvim +Man!"

fish_add_path -a ~/go/bin

# Android SDK
set -gx ANDROID_HOME $HOME/Library/Android/sdk
fish_add_path -a $ANDROID_HOME/platform-tools $ANDROID_HOME/emulator

# maestro-runner
fish_add_path -a $HOME/.maestro-runner/bin

# Pin pi to the Homebrew install so mise node shims can't shadow it.
# Credentials (Brave, GitHub, Linear, gcloud) are injected host-side by the
# gondolin extension, so no secrets are needed in this shell.
# Run pi inside the nono sandbox using the nolabs-ai/pi profile.
# `pi --profile <name>` overrides the sandbox profile; the flag is consumed here
# and not forwarded to pi.
#
# `nono wrap` rather than `nono run`: wrap execs into pi, so pi is the pane's
# foreground process and herdr can recognize the agent (herdr identifies agents
# by the pane's process-group leader, and a `nono run` supervisor hides pi).
# wrap has no supervisor and therefore no proxy, so nono-proxy-ensure keeps a
# shared `nono proxy` per profile and we hand pi its proxy, CA and credential env.
# --block-net is mandatory here: without it wrap permits direct outbound
# connections and the profile's domain allowlist becomes advisory. With it,
# loopback (the proxy, local dev servers) is the only route out.
function pi
    argparse -i profile= -- $argv; or return
    set -l profile nolabs-ai/pi
    if set -q _flag_profile
        set profile $_flag_profile
    end

    set -l root $HOME/.local/state/nono-herdr-proxy
    set -l slug (string replace -a / _ -- $profile)
    set -l port (nono-proxy-ensure $profile)
    if test -z "$port"
        echo "pi: no nono proxy; falling back to supervised run (herdr will not see this agent)" >&2
        nono run --profile $profile --trust-proxy-ca -- pi $argv
        return $status
    end

    set -l token (cat $root/$slug/token)
    set -l url "http://nono:$token@127.0.0.1:$port"
    set -l bundle $root/ca-bundle.pem
    set -l envs \
        HTTP_PROXY=$url HTTPS_PROXY=$url http_proxy=$url https_proxy=$url \
        NO_PROXY=localhost,127.0.0.1 no_proxy=localhost,127.0.0.1 \
        NONO_NO_PROXY=localhost,127.0.0.1 NONO_PROXY_TOKEN=$token \
        NODE_USE_ENV_PROXY=1 \
        SSL_CERT_FILE=$bundle REQUESTS_CA_BUNDLE=$bundle NODE_EXTRA_CA_CERTS=$bundle \
        CURL_CA_BUNDLE=$bundle GIT_SSL_CAINFO=$bundle

    # Tools present the proxy token where a real credential would go; the proxy
    # swaps in the captured secret host-side.
    set -l pfile $HOME/.config/nono/profiles/$profile.json
    if test -f $pfile
        for var in (jq -r '.network.custom_credentials // {} | .[].env_var // empty' $pfile)
            set -a envs $var=$token
        end
    end

    command env $envs nono wrap --profile $profile --allow-cwd --block-net -- pi $argv
end
