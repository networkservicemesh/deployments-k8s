# Basic examples

Contain NSM setup for scalability tests. Identical to basic setup, expect without limits. 

## Requires

- [spire](../../spire)

## Run

2. Register `nsm-system` namespace in spire:

```bash
kubectl exec -n spire spire-server-0 -- \
/opt/spire/bin/spire-server entry create \
-spiffeID spiffe://example.org/ns/nsm-system/sa/default \
-parentID spiffe://example.org/ns/spire/sa/spire-agent \
-selector k8s:ns:nsm-system \
-selector k8s:sa:default
```

3. Register `registry-k8s-sa` in spire:

```bash
kubectl exec -n spire spire-server-0 -- \
/opt/spire/bin/spire-server entry create \
-spiffeID spiffe://example.org/ns/nsm-system/sa/registry-k8s-sa \
-parentID spiffe://example.org/ns/spire/sa/spire-agent \
-selector k8s:ns:nsm-system \
-selector k8s:sa:registry-k8s-sa
```

Choose node for NSM components:
```bash
NODE=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints }}{{ .metadata.name }} {{end}}{{end}}')[0])
```

```bash
cat > patch-registry-k8s.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry-k8s
spec:
  template:
    spec:
      nodeName: ${NODE}
      containers:
        - name: registry
          resources:
            requests:
              memory: "0"
              cpu: "0"
            limits:
              memory: "0"
              cpu: "0"
EOF
```

```bash
cat > patch-admission-webhook.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: admission-webhook-k8s
spec:
  template:
    spec:
      nodeName: ${NODE}
      containers:
        - name: admission-webhook-k8s
          resources:
            requests:
              memory: "0"
              cpu: "0"
            limits:
              memory: "0"
              cpu: "0"
EOF
```

4. Deploy NSM resources:
```bash
kubectl apply -k .
```

```bash
timeout -v --kill-after=10s 1m kubectl wait pod -n nsm-system --timeout=1m --all --for=condition=ready
```

```bash
LOGS_FOLDER=./logs-$(date -Iseconds)
```

```bash
mkdir ${LOGS_FOLDER}
```

```bash
set +m
```
```bash
NSM_PODS=$(kubectl -n nsm-system get pods -o go-template='{{range .items}}{{ if not .spec.taints }}{{ .metadata.name }} {{end}}{{end}}')
for pod in ${NSM_PODS}
do 
  kubectl -n nsm-system logs ${pod} -f >${LOGS_FOLDER}/${pod}.log &
done
```

## Cleanup

To free resources follow the next command:

```bash
kubectl delete mutatingwebhookconfiguration --all
```
```bash
kubectl delete -k .
```
