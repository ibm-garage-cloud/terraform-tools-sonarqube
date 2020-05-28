#!/usr/bin/env bash

if [[ -z "${TMP_DIR}" ]]; then
    TMP_DIR=".tmp"
fi
mkdir -p "${TMP_DIR}"

NAMESPACE="$1"
SERVICE_NAME="$2"
ROUTE_NAME="$3"

cat > "${TMP_DIR}/sonarqube-route.yaml" << EOL
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: ${ROUTE_NAME}
spec:
  port:
    targetPort: http
  tls:
    insecureEdgeTerminationPolicy: Redirect
    termination: edge
  to:
    kind: Service
    name: ${SERVICE_NAME}
    weight: 100
  wildcardPolicy: None
EOL

kubectl apply -n "${NAMESPACE}" -f "${TMP_DIR}/sonarqube-route.yaml" --validate=false
