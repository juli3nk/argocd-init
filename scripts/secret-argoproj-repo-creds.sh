#!/usr/bin/env bash

NAMESPACE="argocd"


command -v kubeseal > /dev/null || { echo -e "\"kubeseal\" command not found" ; exit 1 ; }

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

echo -e "Enter repository's informations\n"

read -p "Name: " REPO_NAME
read -p "Type (git, helm): " REPO_TYPE
read -p "Url: " REPO_URL
read -p "Username: " REPO_USERNAME
read -s -p "Password: " REPO_PASSWORD
echo

cat <<EOF | kubeseal > "${DIR_PATH}/secret-argoproj-repo-creds-${REPO_NAME}.json"
apiVersion: v1
kind: Secret
metadata:
  name: argoproj-repo-creds-${REPO_NAME}
  namespace: ${NAMESPACE}
  labels:
    argocd.argoproj.io/secret-type: repo-creds
stringData:
  type: ${REPO_TYPE}
  url: ${REPO_URL}
  username: ${REPO_USERNAME}
  password: ${REPO_PASSWORD}
EOF
