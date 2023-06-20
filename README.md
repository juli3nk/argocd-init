# Repositories using TLS certificates signed by custom CA

https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#repositories-using-self-signed-tls-certificates-or-are-signed-by-custom-ca

# Argo CD App of Apps Initialization

kubectl --namspace argocd patch app argo-cd --type=json -p='[{"op": "remove", "path": "/metadata/finalizers"}]'
