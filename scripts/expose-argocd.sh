#!/usr/bin/env bash

NAMESPACE="argocd"

REMOTE_PORT="80"

get_next_avail_port() {
    local port="8080"
    local last_port="$(ss -tln | awk '/127.0.0.1:808/ { print $4 }' | sed 's/127.0.0.1://' | sort -n | tail -n 1)"

    if [ -n "$last_port" ]; then
        port="$((last_port + 1))"
    fi

    echo "$port"
}


local_port="$(get_next_avail_port)"

kubectl port-forward \
    $(kubectl get svc --selector "app.kubernetes.io/name=argocd-server" --namespace $NAMESPACE --output=name) \
    --namespace $NAMESPACE \
    ${local_port}:${REMOTE_PORT}
