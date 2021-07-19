#!/bin/bash

function create_endpoint_patches() {
  local nse_count=$1
  local nse_node=$2
  local batch_name=$3

  mkdir -p "./${batch_name}"

  cat > "./${batch_name}/kustomization.yaml" <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE}

namePrefix: ${batch_name}-

resources:
  - nse.yaml

patchesStrategicMerge:
  - patch-nse.yaml
EOF

  cat /dev/null >"./${batch_name}/patch-nse.yaml"
  cat /dev/null >"./${batch_name}/nse.yaml"
  for ((i = 0; i < nse_count; i++)); do
    sed "s/name: nse-kernel/name: nse-kernel-$i/g" ../../../../apps/nse-kernel/nse.yaml >>"./${batch_name}/nse.yaml"
    local cidr_prefix=10.$i.0.0/16
    cat >>"./${batch_name}/patch-nse.yaml" <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse-kernel-$i
spec:
  replicas: 1
  template:
    spec:
      nodeName: ${nse_node}
      containers:
        - name: nse
          env:
            - name: NSM_CIDR_PREFIX
              value: ${cidr_prefix}
            - name: NSM_SERVICE_NAMES
              value: ${NS_LIST}
          resources:
            limits:
              memory: 0Mi
              cpu: 0m
EOF
  done
}
