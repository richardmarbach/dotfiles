# Ensure a long-lived nono filtering/credential proxy is running for a profile.
# Prints the listening port on success.
#
# `pi` runs under `nono wrap` so that pi (not a `nono run` supervisor) is the
# pane's foreground process, which is what herdr needs to recognize the agent.
# wrap has no supervisor and therefore no proxy of its own, so this keeps one
# shared `nono proxy` per profile for domain filtering and credential injection.
# wrap is always paired with --block-net, which makes the proxy the only route
# out; without it wrap enforces no network policy at all.
function nono-proxy-ensure --description "Ensure the shared nono proxy for a profile is running; echo its port"
    set -l profile $argv[1]
    if test -z "$profile"
        echo "nono-proxy-ensure: profile required" >&2
        return 1
    end

    set -l root $HOME/.local/state/nono-herdr-proxy
    set -l slug (string replace -a / _ -- $profile)
    set -l dir $root/$slug
    mkdir -p $dir

    set -l old_umask (umask)
    umask 077

    if not test -f $root/ca-cert.pem
        openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
            -keyout $root/ca-key.pem -out $root/ca-cert.pem -days 365 -nodes \
            -subj "/CN=nono herdr-proxy local CA/O=nono" \
            -addext "basicConstraints=critical,CA:TRUE" \
            -addext "keyUsage=critical,keyCertSign,cRLSign" >/dev/null 2>&1
        if test $status -ne 0
            umask $old_umask
            echo "nono-proxy-ensure: could not generate proxy CA" >&2
            return 1
        end
    end

    if not test -f $dir/token
        openssl rand -hex 32 >$dir/token
    end

    umask $old_umask

    # Sandboxed clients verify against system roots plus our CA.
    if not test -f $root/ca-bundle.pem; or test $root/ca-cert.pem -nt $root/ca-bundle.pem
        cat /etc/ssl/cert.pem $root/ca-cert.pem >$root/ca-bundle.pem
        chmod 644 $root/ca-bundle.pem
    end

    if nono-proxy-port $dir
        return 0
    end

    # Serialize startup so two shells cannot race and leave a stale port file.
    set -l lock $dir/start.lock
    if test -d $lock; and test -n (find $lock -maxdepth 0 -mmin +2 2>/dev/null)
        rmdir $lock 2>/dev/null
    end
    if not mkdir $lock 2>/dev/null
        for _i in (seq 80)
            sleep 0.25
            if nono-proxy-port $dir
                return 0
            end
        end
        echo "nono-proxy-ensure: timed out waiting for another shell to start the proxy" >&2
        return 1
    end

    rm -f $dir/proxy.log $dir/port
    env NONO_PROXY_PASS=(cat $dir/token) \
        NONO_PROXY_CA_CERT=$root/ca-cert.pem \
        NONO_PROXY_CA_KEY=$root/ca-key.pem \
        nohup nono proxy --profile $profile --port 0 >$dir/proxy.log 2>&1 &
    disown

    for _i in (seq 80)
        set -l port (string match -rg 'listening on 127\.0\.0\.1:([0-9]+)' <$dir/proxy.log)[1]
        if test -n "$port"
            echo $port >$dir/port
            rmdir $lock 2>/dev/null
            echo $port
            return 0
        end
        sleep 0.25
    end

    rmdir $lock 2>/dev/null
    echo "nono-proxy-ensure: proxy did not report a port; see $dir/proxy.log" >&2
    return 1
end

function nono-proxy-port --description "Echo a profile state dir's proxy port if it is still listening"
    set -l dir $argv[1]
    test -f $dir/port; or return 1
    set -l port (cat $dir/port)
    test -n "$port"; or return 1
    nc -z 127.0.0.1 $port 2>/dev/null; or return 1
    echo $port
end
