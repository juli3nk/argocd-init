#!/usr/bin/env bash

NAMESPACE="argocd"


command -v helm > /dev/null || { echo -e "\"helm\" command not found" ; exit 1 ; }
command -v kubectl > /dev/null || { echo -e "\"kubectl\" command not found" ; exit 1 ; }

# Uninstall App
apps="$(kubectl --namespace "$NAMESPACE" get apps -o json | jq -r '.items[] | select(.spec.project == "default").metadata.name')"

for app in $apps; do
    kubectl \
        --namespace "$NAMESPACE" \
        delete app "$app"
done

# Uninstall App Projects


# Uninstall Argo-CD
helm --namespace "$NAMESPACE" uninstall argo-cd

for secret in $(kubectl --namespace "$NAMESPACE" get secrets -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'); do
    kubectl --namespace "$NAMESPACE" delete secret "$secret"
done

# Delete CRDs
for crd in $(kubectl get crds --no-headers | awk '/argoproj/ { print $1 }'); do
    kubectl delete crd "$crd"
done

kubectl delete ns "$NAMESPACE"
