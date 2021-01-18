# Test SR-IOV kernel connection

This example shows that NSC and NSE can work with each other over the SR-IOV kernel connection.

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
- ../../apps/kernel-nsc
- ../../apps/kernel-nse
- ../../apps/kernel-ponger


patchesStrategicMerge:
- patch-nsc.yaml
- patch-nse.yaml
EOF
```

Create NSC patch:
```bash
cat > patch-nsc.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nsc
spec:
  template:
    spec:
      containers:
        - name: nsc
          env:
            - name: NSM_NETWORK_SERVICES
              value: kernel://icmp-responder/nsm-1?sriovToken=worker.domain/10G
          resources:
            limits:
              worker.domain/10G: 1
EOF
```

Create NSE patch:
```bash
cat > patch-nse.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse
spec:
  template:
    spec:
      containers:
        - name: nse
          env:
            - name: NSE_LABELS
              value: serviceDomain:worker.domain
            - name: NSE_CIDR_PREFIX
              value: 10.0.0.200/31
          resources:
            limits:
              master.domain/10G: 1
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
```bash
kubectl -n ${NAMESPACE} wait --for=condition=ready --timeout=1m pod -l app=ponger
```

Get NSC pod:
```bash
NSC_POD=$(kubectl -n ${NAMESPACE} get pods -l app=nsc |
  grep -v "NAME" |
  sed -E "s/([.]*) .*/\1/g")
```

Check connection result:
```bash
kubectl -n ${NAMESPACE} logs ${NSC_POD} |
  grep "All client init operations are done."
```

Test connection:
```bash
PING_RESULTS=$(kubectl -n ${NAMESPACE} exec ${NSC_POD} -- ping -c 10 -W 1 10.0.0.200 2>&1) \
  || (echo "${PING_RESULTS}" 1>&2 && false)
```
```bash
PACKET_LOSS="$(echo "${PING_RESULTS}" |
  grep "packet loss" |
  sed -E 's/.* ([0-9]*)(\.[0-9]*)?% packet loss/\1/g')" \
  || (echo "${PING_RESULTS}" 1>&2 && false)
```
```bash
test "${PACKET_LOSS}" -ne 100 \
  || (echo "${PING_RESULTS}" 1>&2 && false)
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ${NAMESPACE}
```