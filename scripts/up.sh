#!/bin/sh
# This file is autogenerated - DO NOT EDIT!
set -euo pipefail
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${BASE_DIR}/.."
(
cd ${REPO_DIR}
kubectl create namespace pg-dfw-demo --dry-run=client -o yaml | kubectl apply -f -
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update bitnami
helm upgrade --install local-postgresql bitnami/postgresql -n pg-dfw-demo -f postgresql/local.yaml
helm upgrade --install foreign-postgresql bitnami/postgresql -n pg-dfw-demo -f postgresql/foreign.yaml
)
