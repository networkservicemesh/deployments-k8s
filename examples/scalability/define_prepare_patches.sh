#!/bin/bash

function prepare_patches() {
  local ns_count=$1
  local nse_count=$2
  local nsc_count=$3
  local nse_node=$4
  local nsc_node=$5
  local test_namespace=$6

  local ns_list=
  local ns_url_list=
  local if_grep_list=
  cat /dev/null > netsvcs.yaml
  for (( i = 0; i < ns_count; i++ ))
  do
    ns=scalability-local-ns-$i
    nsIfName=nsm-$i
    cat >> netsvcs.yaml <<EOF
---
apiVersion: networkservicemesh.io/v1
kind: NetworkService
metadata:
  name: ${ns}
  namespace: nsm-system
spec:
  payload: ETHERNET
  name: ${ns}
EOF
      ns_list=${ns_list},${ns}
      ns_url_list=${ns_url_list},kernel://$ns/$nsIfName
      if_grep_list="${if_grep_list} && [[ 1 -eq \$(ip r | grep \"dev ${nsIfName} scope link\" -c) ]]"
  done

  ns_list="${ns_list:1}"
  ns_url_list="${ns_url_list:1}"
  if_grep_list="${if_grep_list:4}"
  echo "ns_list: ${ns_list}"
  echo "ns_url_list: ${ns_url_list}"
  echo "if_grep_list: ${if_grep_list}"

  cat /dev/null > patch-nse.yaml
  cat /dev/null > nse.yaml
  for (( i = 0; i < nse_count; i++ ))
  do
    sed "s/name: nse-kernel/name: nse-kernel-$i/g" ../../../apps/nse-kernel/nse.yaml >>nse.yaml
    local cidr_prefix=10.$i.0.0/16
    cat >> patch-nse.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse-kernel-$i
  namespace: ${test_namespace}
spec:
  replicas: 1
  template:
    spec:
      nodeName: ${nse_node}
      containers:
        - name: nse
          env:
            - name: NSE_CIDR_PREFIX
              value: ${cidr_prefix}
            - name: NSE_SERVICE_NAMES
              value: ${ns_list}
          resources:
            limits:
              memory: 0Mi
              cpu: 0m
EOF
  done


  cat > patch-nsc.yaml <<EOF
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
              value: ${ns_url_list}
            - name: NSM_REQUEST_TIMEOUT
              value: 1m
          readinessProbe:
            exec:
              command:
                - /bin/sh
                - -c
                - |
                  ${if_grep_list}
            initialDelaySeconds: 0
            periodSeconds: 1
          resources:
            limits:
              memory: 0Mi
              cpu: 0m
EOF
}
