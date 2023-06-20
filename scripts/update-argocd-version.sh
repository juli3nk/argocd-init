#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo -e "no environment provided"
    exit 1
fi

if [ $(ls -1 envs/ | grep -Ec "^${1}$") -eq 0 ]; then
    echo -e "invalid environment \"${1}\""
    exit 1
fi

DIR_PATH="envs/${1}/charts/argo-cd"
CHART_YAML_FILE="${DIR_PATH}/Chart.yaml"

echo -e "Enter ArgoCD chart's informations\n"

read -p "Chart version: " VERSION_CHART
read -p "ArgoCD version: " VERSION_REPO_CHART_ARGOCD

yq e '.version = "$VERSION_CHART"' -i "$CHART_YAML_FILE"
yq e '.dependencies[0].version = "$VERSION_REPO_CHART_ARGOCD"' -i "$CHART_YAML_FILE"

helm dep update "${DIR_PATH}/"