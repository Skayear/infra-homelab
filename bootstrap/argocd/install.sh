#!/bin/bash
set -e

NAMESPACE="argocd"
RELEASE="argocd"
CHART="argo/argo-cd"
CHART_VERSION="7.8.23"

echo "==> Agregando repo de Helm..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "==> Instalando ArgoCD en namespace '${NAMESPACE}'..."
helm upgrade --install ${RELEASE} ${CHART} \
  --version ${CHART_VERSION} \
  --namespace ${NAMESPACE} \
  --create-namespace \
  --values "$(dirname "$0")/values.yaml" \
  --wait

echo "==> Aplicando App of Apps..."
kubectl apply -f "$(dirname "$0")/app-of-apps.yaml"

echo ""
echo "==> ArgoCD instalado correctamente."
echo "    Para acceder a la UI temporalmente:"
echo "    kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo ""
echo "    Password inicial del admin:"
echo "    kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d"
