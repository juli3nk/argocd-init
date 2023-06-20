#!/usr/bin/env bash

GS_ORG=${1:-}
GS_REPO=${2:-}
REPO_DIR_PATH=${3:-}
APP_NAME=${4:-}
GIT_SVC_DOMAIN=${5:-github.com}

ENV_NAME="staging"

ARGOCD_NAME="argo-cd"
ARGOCD_HELM_CHART_URL="https://argoproj.github.io/argo-helm"
ARGOCD_HELM_CHART_VERSION="5.36.3"
ARGOCD_NAMESPACE="argocd"

REPO_URL="https://${GIT_SVC_DOMAIN}/${GS_ORG}/${GS_REPO}.git"


command -v helm > /dev/null || { echo -e "\"helm\" command not found" ; exit 1 ; }

if [ -z "$GS_ORG" ]; then
  echo -e "Git org is not provided"
  exit 1
fi

if [ -z "$GS_REPO" ]; then
  echo -e "Git repo is not provided"
  exit 1
fi

if [ -z "$REPO_DIR_PATH" ]; then
  echo -e "repository directory path is not provided"
  exit 1
fi

if [ ! -d "$REPO_DIR_PATH" ]; then
  echo -e "repository directory path does not exit"
  exit 1
fi

if [ $(git ls-remote git@${GIT_SVC_DOMAIN}:${GS_ORG}/${GS_REPO}.git &> /dev/null ; echo $?) -gt 0 ]; then
  echo -e "repository \"${GS_REPO}\" does not exist"
  exit 1
fi


PROJ_EXISTS="false"
if [ ! -d "${REPO_DIR_PATH}/${GS_REPO}" ]; then
    mkdir -p "${REPO_DIR_PATH}/${GS_REPO}/envs/${ENV_NAME}/{apps,charts,customs,scripts}"

    # Scripts
    cp scripts/*.sh "${REPO_DIR_PATH}/${GS_REPO}/scripts/"
else
    PROJ_EXISTS="true"
fi


cd "${REPO_DIR_PATH}/${GS_REPO}"

if [ "$PROJ_EXISTS" == "false" -a "$APP_NAME" == "root" ]; then
    # Argo CD helm chart
    mkdir -p charts/argo-cd

    cat << EOF > charts/argo-cd/Chart.yaml
---
apiVersion: v2
name: argo-cd
version: 1.0.0
dependencies:
  - name: $ARGOCD_NAME
    repository: $ARGOCD_HELM_CHART_URL
    version: $ARGOCD_HELM_CHART_VERSION
EOF

    cat << EOF > charts/argo-cd/values.yaml
---
argo-cd:
  dex:
    enabled: false
  server:
    extraArgs:
      - --insecure
    config:
      repositories: |
        - type: helm
          name: $ARGOCD_NAME
          url: $ARGOCD_HELM_CHART_URL
EOF

    echo "charts/" > charts/argo-cd/.gitignore
fi

# App Root
mkdir -p apps/templates

cat << EOF > apps/Chart.yaml
---
apiVersion: v2
name: $APP_NAME
version: 1.0.0
EOF

cat << EOF > apps/values.yaml
spec:
  destination:
    server:
      local: https://kubernetes.default.svc
  source:
    repoURL: $REPO_URL
    targetRevision: HEAD
EOF

cat << EOF > apps/templates/${APP_NAME}.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: $APP_NAME
  namespace: $ARGOCD_NAMESPACE
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  destination:
    server: {{ .Values.spec.destination.server.local }}
    namespace: $ARGOCD_NAMESPACE
  source:
    path: apps/
    repoURL: {{ .Values.spec.source.repoURL }}
    targetRevision: {{ .Values.spec.source.targetRevision }}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# App ArgoCD
if [ "$PROJ_EXISTS" == "false" -a "$APP_NAME" == "root" ]; then
    cat << EOF > apps/templates/argo-cd.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argo-cd
  namespace: $ARGOCD_NAMESPACE
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  destination:
    server: {{ .Values.spec.destination.server.local }}
    namespace: $ARGOCD_NAMESPACE
  source:
    path: charts/argo-cd
    repoURL: {{ .Values.spec.source.repoURL }}
    targetRevision: {{ .Values.spec.source.targetRevision }}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
fi


# Helm
if [ "$PROJ_EXISTS" == "false" -a "$APP_NAME" == "root" ]; then
    helm repo add "$ARGOCD_NAME" "$ARGOCD_HELM_CHART_URL"
    helm dep update charts/argo-cd/
fi

# Git
if [ "$PROJ_EXISTS" == "false" ]; then
    git init
    git branch -m main
    git remote add origin "git@${GIT_SVC_DOMAIN}:${GS_ORG}/${GS_REPO}.git"

    git add .
    git commit -m "Initial commit"
    git push -u origin main
else
    git add .
    git commit -m "Add ${APP_NAME} app"
    git push origin main
fi


# Installation instruction
clear

if [ "$PROJ_EXISTS" == "false" -a "$APP_NAME" == "root" ]; then
    echo -e "# Installing custom Argo CD Helm chart with the command below:\n\n"
    echo -e "kubectl create namespace ${ARGOCD_NAMESPACE}"
    echo -e "helm -n ${ARGOCD_NAMESPACE} install argo-cd ${REPO_DIR_PATH}/${GS_REPO}/charts/argo-cd/"

    echo -e "\n# Get initial admin password\n\n"
    echo -e "kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d ; echo"
fi

echo -e "\n# Deploy ${APP_NAME} app\n\n"
echo -e "helm -n ${ARGOCD_NAMESPACE} template ${REPO_DIR_PATH}/${GS_REPO}/apps/${APP_NAME}/ | kubectl apply -f -"
