#!/bin/bash

function generate_netsvc() {
  local ns_count=$1

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

  NS_LIST="${ns_list:1}"
  NS_URL_LIST="${ns_url_list:1}"
  IF_GREP_LIST="${if_grep_list:4}"
}
