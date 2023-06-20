#!/usr/bin/env bash

NAMESPACE="argocd"
SECRET_NAME="argocd-initial-admin-secret"


command -v kubectl > /dev/null || { echo -e "\"kubectl\" command not found" ; exit 1 ; }

kubectl \
    --namespace "$NAMESPACE" \
    get secret "$SECRET_NAME" \
    -o jsonpath='{.data.password}' \
    | base64 -d ; echo
