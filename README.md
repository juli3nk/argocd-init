# Argo CD App of Apps Initialization

kubectl patch app argo-cd --type=json -p='[{"op": "remove", "path": "/metadata/finalizers"}]'
