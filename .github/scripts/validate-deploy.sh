#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

export KUBECONFIG="${SCRIPT_DIR}/.kube/config"

CLUSTER_TYPE="$1"
NAMESPACE="$2"

echo "Verifying resources in $NAMESPACE namespace"

PODS=$(kubectl get -n "${NAMESPACE}" pods -o jsonpath='{range .items[*]}{.status.phase}{": "}{.kind}{"/"}{.metadata.name}{"\n"}{end}' | grep -v "Running" | grep -v "Succeeded")
POD_STATUSES=$(echo "${PODS}" | sed -E "s/(.*):.*/\1/g")
if [[ -n "${POD_STATUSES}" ]]; then
  echo "  Pods have non-success statuses: ${PODS}"
  exit 1
fi

if [[ "${CLUSTER_TYPE}" =~ ocp4 ]] && [[ -n "${CONSOLE_LINK_NAME}" ]]; then
  if kubectl get consolelink "toolkit-${CONSOLE_LINK_NAME}" 1> /dev/null 2> /dev/null; then
    echo "ConsoleLink installed"
    kubectl get consolelink "toolkit-${CONSOLE_LINK_NAME}"
  else
    echo "ConsoleLink not found"
    kubectl get consolelink
    exit 1
  fi
fi

set -e

if [[ "${CLUSTER_TYPE}" == "kubernetes" ]] || [[ "${CLUSTER_TYPE}" =~ iks ]]; then
  ENDPOINTS=$(kubectl get ingress -n "${NAMESPACE}" -o jsonpath='{range .items[*]}{range .spec.rules[*]}{"https://"}{.host}{"\n"}{end}{end}')
else
  ENDPOINTS=$(kubectl get route -n "${NAMESPACE}" -o jsonpath='{range .items[*]}{"https://"}{.spec.host}{"\n"}{end}')
fi

echo "Validating endpoints:\n${ENDPOINTS}"

echo "${ENDPOINTS}" | while read -r endpoint; do
  if [[ -n "${endpoint}" ]]; then
    if [[ "${endpoint}" =~ destroytest ]]; then
      echo "Skipping destroytest endpoint"
    else
      "${SCRIPT_DIR}/waitForEndpoint.sh" "${endpoint}" 10 10
    fi
  fi
done

CONFIG_URLS=$(kubectl get configmap -n "${NAMESPACE}" -l grouping=garage-cloud-native-toolkit -l app.kubernetes.io/component=tools -o json | jq '.items[].data | to_entries | select(.[].key | endswith("_URL")) | .[].value' | sed "s/\"//g")

echo "${CONFIG_URLS}" | while read url; do
  if [[ -n "${url}" ]]; then
    ${SCRIPT_DIR}/waitForEndpoint.sh "${url}" 10 10
  fi
done

exit 0
