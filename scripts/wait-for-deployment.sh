#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)

NAMESPACE="$1"
DEPLOYMENT="$2"

set -e

kubectl rollout status deployment "${DEPLOYMENT}" -n "${NAMESPACE}" --timeout=30m

CONFIG_URLS=$(kubectl get configmap -n "${NAMESPACE}" sonarqube-config -o jsonpath='{.data.SONARQUBE_URL}')

echo "${CONFIG_URLS}" | while read url; do
  if [[ -n "${url}" ]]; then
    "${SCRIPT_DIR}/waitForEndpoint.sh" "${url}" 30 20
  fi
done
