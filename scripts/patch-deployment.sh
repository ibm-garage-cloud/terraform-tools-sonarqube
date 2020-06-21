#!/usr/bin/env bash

NAMESPACE="$1"
DEPLOYMENT_NAME="$2"

kubectl patch deployment -n "${NAMESPACE}" "${DEPLOYMENT_NAME}" --type json -p='[{"op": "replace", "path": "/spec/progressDeadlineSeconds", "value": 1200}]'
