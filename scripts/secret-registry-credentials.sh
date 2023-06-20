#!/usr/bin/env bash

command -v kubectl > /dev/null || { echo -e "\"kubectl\" command not found" ; exit 1 ; }
command -v kubeseal > /dev/null || { echo -e "\"kubeseal\" command not found" ; exit 1 ; }
command -v yq > /dev/null || { echo -e "\"yq\" command not found" ; exit 1 ; }

if [ -z "$1" ]; then
    echo -e "no environment provided"
    exit 1
fi

if [ $(ls -1 envs/ | grep -Ec "^${1}$") -eq 0 ]; then
    echo -e "invalid environment \"${1}\""
    exit 1
fi

DIR_PATH="envs/${1}/customs/universalistes"

mkdir -p "$DIR_PATH"

echo -e "Enter registry's informations\n"

read -p "Server: " REGISTRY_SERVER
read -p "Username: " REGISTRY_USERNAME
read -s -p "Password: " REGISTRY_PASSWORD
echo -e
read -p "Email: " REGISTRY_EMAIL
echo

for ns in $(yq -N eval '. | select(.kind == "Namespace") | .metadata.name' envs/${1}/apps/templates/argocd-proj-universalistes.yaml); do
    kubectl \
        --namespace "$ns" \
        create secret \
        docker-registry regcred \
        --docker-server="$REGISTRY_SERVER" \
        --docker-username="$REGISTRY_USERNAME" \
        --docker-password="$REGISTRY_PASSWORD" \
        --docker-email="$REGISTRY_EMAIL" \
        --dry-run=client \
        --output=json \
        | kubeseal > "${DIR_PATH}/secret-registry-credentials-${ns}.json"
done
