#!/bin/bash

function create_client_patches() {
  local nsc_count=$1
  local nsc_node=$2
  local batch_name=$3

  mkdir -p "./${batch_name}"

  cat > "./${batch_name}/kustomization.yaml" <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE}

namePrefix: ${batch_name}-

bases:
  - ../../../../../apps/nsc-kernel

patchesStrategicMerge:
  - patch-nsc.yaml
EOF

  cat >"./${batch_name}/patch-nsc.yaml" <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nsc-kernel
spec:
  replicas: ${nsc_count}
  template:
    spec:
      nodeName: ${nsc_node}
      containers:
        - name: nsc
          env:
            - name: NSM_NETWORK_SERVICES
              value: ${NS_URL_LIST}
            - name: NSM_REQUEST_TIMEOUT
              value: 1m
          readinessProbe:
            exec:
              command:
                - /bin/sh
                - -c
                - |
                  ${IF_GREP_LIST}
            initialDelaySeconds: 0
            periodSeconds: 1
          resources:
            limits:
              memory: 0Mi
              cpu: 0m
EOF
}
