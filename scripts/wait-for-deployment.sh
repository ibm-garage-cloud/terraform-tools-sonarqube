#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)

NAMESPACE="$1"
DEPLOYMENT="$2"

kubectl rollout status deployment "${DEPLOYMENT}" -n "${NAMESPACE}" --timeout=30m

CONFIG_URLS=$(kubectl get configmap -n "${NAMESPACE}" -l grouping=garage-cloud-native-toolkit -l app.kubernetes.io/component=tools -o json | jq '.items[].data | to_entries | select(.[].key | endswith("_URL")) | .[].value')

echo "${CONFIG_URLS}" | while read url; do
  if [[ -n "${url}" ]]; then
    "${SCRIPT_DIR}/waitForEndpoint.sh" "${url}" 30 20
  fi
done
