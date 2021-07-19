# Scalability heal test

This test has the following scenario:
1. Deploy endpoints
2. Deploy clients
3. Delete endpoints
4. Wait few seconds to capture load during healing
5. Deploy new endpoints
6. Wait for all connections to heal 
7. Delete everything
8. Gather statistics

## Run

Set test parameters:
```bash
. ./set_params.sh
```

Save test time, for drawing plots:
```bash
TEST_TIME_START=$(date -Iseconds)
```

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f ../../namespace.yaml)[0])
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

Select nodes to deploy NSC and NSE:
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

Deploy everything:
```bash
. ../define_generate_netsvc.sh
. ../define_create_client_patches.sh
. ../define_create_endpoint_patches.sh
```

```bash
generate_netsvc ${TEST_NS_COUNT}
```
```bash
kubectl apply -f netsvcs.yaml
```

```bash
create_endpoint_patches ${TEST_NSE_COUNT} ${NSE_NODE} endpoints-0 0
```
```bash
kubectl apply -k ./endpoints-0
```
```bash
timeout -v --kill-after=10s 3m kubectl wait pod -n ${NAMESPACE} --timeout=3m -l app=nse-kernel --for=condition=ready
```
```bash
create_client_patches ${TEST_NSC_COUNT} ${NSC_NODE} clients
```
```bash
kubectl apply -k ./clients
```
```bash
timeout -v --kill-after=10s 3m kubectl wait pod -n ${NAMESPACE} --timeout=3m -l app=nsc-kernel --for=condition=ready
```
```bash
EVENT_LIST="${EVENT_LIST} CONNECTIONS_READY"
EVENT_TIME_CONNECTIONS_READY="$(date -Iseconds)"
EVENT_TEXT_CONNECTIONS_READY="Connections established"
```

Make sure that all requests have really finished:
```bash
CLIENTS="$(kubectl -n ${NAMESPACE} get pods -o go-template='{{range .items}}{{ .metadata.name }} {{end}}' -l app=nsc-kernel)"
for client in ${CLIENTS} ; do
  COUNT="$(kubectl -n ${NAMESPACE} logs ${client} | grep "successfully connected to scalability-local-ns" -c)"
  if [[ ${COUNT} -ne ${TEST_NS_COUNT} ]]; then
    echo "client ${client} is not yet finished: ${COUNT} connections, need ${TEST_NS_COUNT}"
    $(exit 1)
    break
  else
    echo "client ${client} is good to do"
  fi
done
```
```bash
EVENT_LIST="${EVENT_LIST} REQUESTS_FINISHED"
EVENT_TIME_REQUESTS_FINISHED="$(date -Iseconds)"
EVENT_TEXT_REQUESTS_FINISHED="Requests finished"
```
```bash
sleep 15
```

Run test scenario actions:
```bash
EVENT_LIST="${EVENT_LIST} DELETE_ENDPOINTS"
EVENT_TIME_DELETE_ENDPOINTS="$(date -Iseconds)"
EVENT_TEXT_DELETE_ENDPOINTS="Delete endpoints..."
```
```bash
timeout -v --kill-after=10s 3m kubectl -n ${NAMESPACE} delete -k ./endpoints-0 --cascade=foreground
```
```bash
EVENT_LIST="${EVENT_LIST} ENDPOINTS_DELETED"
EVENT_TIME_ENDPOINTS_DELETED="$(date -Iseconds)"
EVENT_TEXT_ENDPOINTS_DELETED="Endpoints deleted"
```

Make sure we don't have any open connections:
```bash
for nsc in $(kubectl -n ${NAMESPACE} get pods -l app=nsc-kernel -o go-template='{{range .items}}{{ .metadata.name }} {{end}}'); do
  echo client ${nsc}
  echo $(kubectl -n ${NAMESPACE} exec ${nsc} -- ip r)
  if [[ 0 -ne $(kubectl -n ${NAMESPACE} exec ${nsc} -- ip r | grep "dev nsm" -c) ]]; then
    echo "client still have open NSM connections: ${nsc}"
    $(exit 1)
    break
  else 
    echo "client doesn't have open NSM connections: ${nsc}"
  fi
done
```
```bash
sleep 15
```

Redeploy endpoints:
```bash
create_endpoint_patches ${TEST_NSE_COUNT} ${NSE_NODE} endpoints-1 1
```
```bash
EVENT_LIST="${EVENT_LIST} RECREATE_ENDPOINTS"
EVENT_TIME_RECREATE_ENDPOINTS="$(date -Iseconds)"
EVENT_TEXT_RECREATE_ENDPOINTS="Create new endpoints"
```
```bash
kubectl apply -k ./endpoints-1
```
```bash
timeout -v --kill-after=10s 3m kubectl wait pod -n ${NAMESPACE} --timeout=3m -l app=nse-kernel --for=condition=ready
```

Wait for all connections to heal:
```bash
rc=0
for nsc in $(kubectl -n ${NAMESPACE} get pods -l app=nsc-kernel -o go-template='{{range .items}}{{ .metadata.name }} {{end}}'); do
  echo client ${nsc}
  kubectl -n ${NAMESPACE} exec ${nsc} -- ip r
  if [[ ${TEST_NS_COUNT} -ne $(kubectl -n ${NAMESPACE} exec ${nsc} -- ip r | grep "10.1" | grep "dev nsm" -c) ]]; then
    echo "client is still not healed: ${nsc}"
    rc=1
    break
  else
    echo "client is good to go: ${nsc}"
  fi
done
$(exit ${rc})
```
```bash
EVENT_LIST="${EVENT_LIST} HEAL_FINISHED"
EVENT_TIME_HEAL_FINISHED="$(date -Iseconds)"
EVENT_TEXT_HEAL_FINISHED="Heal finished"
```
```bash
sleep 15
```

Delete everything:
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
RESULT_DIR="result_data-${TEST_TIME_START}-netsvc=${TEST_NS_COUNT}-nse=${TEST_NSE_COUNT}-nsc=${TEST_NSC_COUNT}"
PARAM_ANNOTATION="heal case, ${TEST_NS_COUNT} service(s), ${TEST_NSE_COUNT} NSE(s), ${TEST_NSC_COUNT} NSC(s)"
if [[ "${TEST_REMOTE_CASE}" == "true" ]]; then
  PARAM_ANNOTATION="${PARAM_ANNOTATION}, remote case"
  RESULT_DIR="${RESULT_DIR}-remote"
else
  PARAM_ANNOTATION="${PARAM_ANNOTATION}, local case"
  RESULT_DIR="${RESULT_DIR}-local"
fi
```
```bash
. ../define_save_data.sh
```
```bash
. ../save_metrics.sh
```

## Cleanup

Kill proxy to prometheus:
```bash
PORT_FORWARDER_JOB=$(jobs | grep "prometheus port-forward" | cut -d] -f1 | cut -c 2-)
if [[ "${PORT_FORWARDER_JOB}" != "" ]]; then
  kill %${PORT_FORWARDER_JOB}
  cat port_forwarder_out.log
  rm port_forwarder_out.log
fi
```

Delete ns:
```bash
kubectl delete ns ${NAMESPACE} --ignore-not-found
```
```bash
kubectl delete -f netsvcs.yaml --ignore-not-found
```
