#!/usr/bin/env bash

NAMESPACE="argocd"


command -v helm > /dev/null || { echo -e "\"helm\" command not found" ; exit 1 ; }
command -v kubectl > /dev/null || { echo -e "\"kubectl\" command not found" ; exit 1 ; }

if [ -z "$1" ]; then
    echo -e "no environment provided"
    exit 1
fi

if [ $(ls -1 envs/ | grep -Ec "^${1}$") -eq 0 ]; then
    echo -e "invalid environment \"${1}\""
    exit 1
fi

DIR_PATH="envs/${1}"

# Install Argo-CD
kubectl create ns "$NAMESPACE"

helm \
    --namespace "$NAMESPACE" \
    install argo-cd \
    "${DIR_PATH}/charts/argo-cd/"

sleep 60

# Install App
helm \
    --namespace "$NAMESPACE" \
    template "${DIR_PATH}/apps/" \
    | kubectl apply -f -
