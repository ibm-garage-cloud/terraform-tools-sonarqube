#!/usr/bin/env bash

NAMESPACE="$1"
ROUTE_NAME="$2"

kubectl delete route "${ROUTE_NAME}" --namespace "${NAMESPACE}"

exit 0
