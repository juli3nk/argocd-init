#!/usr/bin/env bash

GH_ORG=${1:-}
GH_REPO=${2:-}
REPO_DIR_PATH=${3:-}

HELM_CHART_URL_ARGOCD="https://argoproj.github.io/argo-helm"
NAME_ARGOCD="argo-cd"
REPO_URL="https://github.com/${GH_ORG}/${GH_REPO}.git"


command -v helm > /dev/null || { echo -e "\"helm\" command not found" ; exit 1 ; }

if [ -z "$GH_ORG" ]; then
  echo -e "Github org is not provided"
  exit 1
fi

if [ -z "$GH_REPO" ]; then
  echo -e "Github repo is not provided"
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

if [ $(git ls-remote git@github.com:${GH_ORG}/${GH_REPO}.git &> /dev/null ; echo $?) -gt 0 ]; then
  echo -e "repository \"${GH_REPO}\" does not exist"
  exit 1
fi


mkdir -p ${REPO_DIR_PATH}/${GH_REPO}/charts/argo-cd

cd ${REPO_DIR_PATH}/${GH_REPO}

# 
cat << EOF > charts/argo-cd/Chart.yaml
---
apiVersion: v2
name: argo-cd
version: 1.0.0
dependencies:
  - name: $NAME_ARGOCD
    repository: $HELM_CHART_URL_ARGOCD
    version: 4.2.2
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
          name: $NAME_ARGOCD
          url: $HELM_CHART_URL_ARGOCD
EOF

echo "charts/" > charts/argo-cd/.gitignore

# Root app
mkdir -p apps/templates

cat << EOF > apps/Chart.yaml
---
apiVersion: v2
name: root
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

cat << EOF > apps/templates/root.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  destination:
    server: {{ .Values.spec.destination.server.local }}
    namespace: default
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
cat << EOF > apps/templates/argo-cd.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argo-cd
  namespace: default
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  destination:
    server: {{ .Values.spec.destination.server.local }}
    namespace: default
  source:
    path: charts/argo-cd
    repoURL: {{ .Values.spec.source.repoURL }}
    targetRevision: {{ .Values.spec.source.targetRevision }}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# Helm
helm repo add $NAME_ARGOCD $HELM_CHART_URL_ARGOCD
helm dep update charts/argo-cd/

# Git
git init
git branch -m main
git remote add origin git@github.com:${GH_ORG}/${GH_REPO}.git

git add .
git commit -m "Initial commit"
git push -u origin main

# Installation instruction
clear

echo -e "# Installing custom Argo CD Helm chart with the command below:\n\n"
echo -e "helm install argo-cd ${REPO_DIR_PATH}/${GH_REPO}/charts/argo-cd/"

echo -e "helm template ${REPO_DIR_PATH}/${GH_REPO}/apps/ | kubectl apply -f -"
