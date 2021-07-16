# Test kernel to kernel connection

This is an NSM system scalability test.

## Run

Set test parameters:
```bash
. ./set_params.sh
```
```bash
TEST_TIME_START=$(date -Iseconds)
```

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f ../namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

Register namespace in `spire` server:
```bash
kubectl exec -n spire spire-server-0 -- \
/opt/spire/bin/spire-server entry create \
-spiffeID spiffe://example.org/ns/${NAMESPACE}/sa/default \
-parentID spiffe://example.org/ns/spire/sa/spire-agent \
-selector k8s:ns:${NAMESPACE} \
-selector k8s:sa:default
```

Create customization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE}

bases:
  - ../../../apps/nsc-kernel

resources:
  - nse.yaml

patchesStrategicMerge:
  - patch-nsc.yaml
  - patch-nse.yaml
EOF
```

Select node to deploy NSC and NSE:
```bash
NODES=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints }}{{ .metadata.name }} {{end}}{{end}}'))
NSE_NODE=${NODES[0]}
if [[ "${TEST_REMOTE_CASE}" == "true" ]]; then
  NSC_NODE=${NODES[1]}
else
  NSC_NODE=${NODES[0]}
fi
echo NSE_NODE ${NSE_NODE}, NSC_NODE ${NSC_NODE}
```

Deploy pods
```bash
. ../define_prepare_patches.sh
```
```bash
prepare_patches ${TEST_NS_COUNT} ${TEST_NSE_COUNT} ${TEST_NSC_COUNT} ${NSE_NODE} ${NSC_NODE}
```
```bash
kubectl apply -f netsvcs.yaml
```
```bash
kubectl apply -k .
```
```bash
timeout -v --kill-after=10s 3m kubectl wait pod -n ${NAMESPACE} --timeout=3m -l app=nse-kernel --for=condition=ready
```
```bash
timeout -v --kill-after=10s 3m kubectl wait pod -n ${NAMESPACE} --timeout=3m -l app=nsc-kernel --for=condition=ready
```
```bash
EVENT_LIST="${EVENT_LIST} CLIENTS_READY"
EVENT_TIME_CLIENTS_READY="$(date -Iseconds)"
EVENT_TEXT_CLIENTS_READY="Clients ready"
```
```bash
CLIENTS="$(kubectl -n ${NAMESPACE} get pods -o go-template='{{range .items}}{{ .metadata.name }} {{end}}' -l app=nsc-kernel)"
for client in ${CLIENTS} ; do
  COUNT="$(kubectl -n ${NAMESPACE} logs ${client} | grep "successfully connected to scalability-local-ns" -c)"
  if [[ ${COUNT} -ne ${TEST_NS_COUNT} ]]; then
    echo client ${client} is not yet finished: count ${COUNT}, need ${TEST_NS_COUNT} 
    $(exit 1)
    break
  fi
done
echo All clients finished requests
```
```bash
EVENT_LIST="${EVENT_LIST} REQUESTS_FINISHED"
EVENT_TIME_REQUESTS_FINISHED="$(date -Iseconds)"
EVENT_TEXT_REQUESTS_FINISHED="Requests finished"
```
```bash
sleep 15
```
```bash
EVENT_LIST="${EVENT_LIST} DELETE_1 DELETE_2"
EVENT_TIME_DELETE_1="$(date -Iseconds)"
```
```bash
if [[ "${TEST_ENABLE_HEAL}" == "true" ]]; then
  kubectl -n ${NAMESPACE} delete -f ./nse.yaml &&
  timeout -v --kill-after=10s 3m kubectl -n ${NAMESPACE} wait --for=delete --timeout=3m pod -l app=nse-kernel &&
  EVENT_TEXT_DELETE_1="Delete endpoints..." &&
  EVENT_TEXT_DELETE_2="Endpoints deleted"
else
  kubectl -n ${NAMESPACE} delete deployment nsc-kernel &&
  timeout -v --kill-after=10s 3m kubectl -n ${NAMESPACE} wait --for=delete --timeout=3m pod -l app=nsc-kernel &&
  EVENT_TEXT_DELETE_1="Delete clients..." &&
  EVENT_TEXT_DELETE_2="Clients deleted"
fi
```
```bash
EVENT_TIME_DELETE_2="$(date -Iseconds)"
```
```bash
sleep 15
```
```bash
EVENT_LIST="${EVENT_LIST} DELETE_NAMESPACE"
EVENT_TIME_DELETE_NAMESPACE="$(date -Iseconds)"
EVENT_TEXT_DELETE_NAMESPACE="Delete namespace..."
```
```bash
kubectl delete ns ${NAMESPACE}
```
```bash
EVENT_LIST="${EVENT_LIST} NAMESPACE_DELETED"
EVENT_TIME_NAMESPACE_DELETED="$(date -Iseconds)"
EVENT_TEXT_NAMESPACE_DELETED="Namespace deleted"
```
```bash
sleep 15
```
```bash
TEST_TIME_END="$(date -Iseconds)"
```

Open connection to prometheus:
```bash
set +m
```
```bash
kubectl -n prometheus port-forward $(kubectl -n prometheus get pod --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' -l app=prometheus-server) 9090:9090 2>&1 >port_forwarder_out.log &
```
```bash
PROM_URL="http://localhost:9090"
```
```bash
curl "${PROM_URL}/-/healthy" --silent --show-error
```

Save statistics:
```bash
RESULT_DIR="result_data-${TEST_TIME_START}-netsvc=${TEST_NS_COUNT}-nse=${TEST_NSE_COUNT}-nsc=${TEST_NSC_COUNT}-heal=${TEST_ENABLE_HEAL}"
PARAM_ANNOTATION="${TEST_NS_COUNT} service(s), ${TEST_NSE_COUNT} NSE(s), ${TEST_NSC_COUNT} NSC(s)" 
if [[ "${TEST_ENABLE_HEAL}" == "true" ]]; then
  PARAM_ANNOTATION="${PARAM_ANNOTATION}, with heal"
else
  PARAM_ANNOTATION="${PARAM_ANNOTATION}, without heal"
fi
if [[ "${TEST_REMOTE_CASE}" == "true" ]]; then
  PARAM_ANNOTATION="${PARAM_ANNOTATION}, remote case"
  RESULT_DIR="${RESULT_DIR}-remote"
else
  PARAM_ANNOTATION="${PARAM_ANNOTATION}, local case"
  RESULT_DIR="${RESULT_DIR}-local"
fi
```
```bash
mkdir "${RESULT_DIR}"
```
```bash
. ../define_save_data.sh
```

Save numeric data and plots:
```bash
. ../save_metrics.sh
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ${NAMESPACE} --ignore-not-found
```
```bash
kubectl delete -f netsvcs.yaml --ignore-not-found
```

Kill proxy to prometheus:
```bash
PORT_FORWARDER_JOB=$(jobs | grep "prometheus port-forward" | cut -d] -f1 | cut -c 2-)
if [[ "${PORT_FORWARDER_JOB}" != "" ]]; then
  kill %${PORT_FORWARDER_JOB}
  cat port_forwarder_out.log
  rm port_forwarder_out.log
fi
```
