# Test VFIO connection

This example shows that NSC and NSE can work with each other over the VFIO connection.

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f namespace.yaml)[0])
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
- ../../apps/vfio-nsc
- ../../apps/vfio-nse
EOF
```

Deploy NSC and NSE:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl -n ${NAMESPACE} wait --for=condition=ready --timeout=1m pod -l app=nsc
```
```bash
kubectl -n ${NAMESPACE} wait --for=condition=ready --timeout=1m pod -l app=nse
```

Get NSC pod:
```bash
NSC_POD=$(kubectl -n ${NAMESPACE} get pods -l app=nsc |
  grep -v "NAME" |
  sed -E "s/([.]*) .*/\1/g")
```

Check connection result:
```bash
kubectl -n ${NAMESPACE} logs ${NSC_POD} sidecar |
  grep "All client init operations are done."
```

Test connection:
```bash
PING_RESULTS=$(kubectl -n ${NAMESPACE} exec ${NSC_POD} --container pinger -- /bin/bash -c ' \
  /root/dpdk-pingpong/build/app/pingpong                                                    \
    --no-huge                                                                               \
    --                                                                                      \
    -n 500                                                                                  \
    -c                                                                                      \
    -C 0a:11:22:33:44:55                                                                    \
    -S 0a:55:44:33:22:11                                                                    \
' 2>&1) || (echo "${PING_RESULTS}" 1>&2 && false)
```
```bash
PONG_PACKETS="$(echo "${PING_RESULTS}"                      |
                grep "rx .* pong packets"                   |
                sed -E 's/rx ([0-9]*) pong packets/\1/g')"  \
  || (echo "${PING_RESULTS}" 1>&2 && false)
```
```bash
test "${PONG_PACKETS}" -ne 0 \
  || (echo "${PING_RESULTS}" 1>&2 && false)
```

## Cleanup

Stop ponger
```bash
NSE_POD=$(kubectl -n ${NAMESPACE} get pods -l app=nse |
  grep -v "NAME" |
  sed -E "s/([.]*) .*/\1/g")
```
```bash
kubectl -n ${NAMESPACE} exec ${NSE_POD} --container ponger -- /bin/bash -c '                  \
  sleep 10 && kill $(ps -A | grep "pingpong" | sed -E "s/ *([0-9]*).*/\1/g") 1>/dev/null 2>&1 & \
'
```

Delete ns
```bash
kubectl delete ns ${NAMESPACE}
```