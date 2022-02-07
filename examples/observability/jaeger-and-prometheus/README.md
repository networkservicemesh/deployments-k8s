# Jaeger and Prometheus Example

This example demonstrates how to setup Open Telemetry Collector with Jaeger and Prometheus to gather telemetry data from NSM components.

## Run
Apply Jaeger, Prometheus and OpenTelemetry Collector:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/observability/jaeger-and-prometheus?ref=da0228654084085b3659ed6b519f66f44b6796ce
```

Wait for OpenTelemetry Collector POD status ready:
```bash
kubectl wait -n observability --timeout=1m --for=condition=ready pod -l app=opentelemetry
```

Create ns for NSM deployments:
```bash
kubectl create ns nsm-system
```

Apply NSM resources for basic tests:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/observability/jaeger-and-prometheus/nsm-system?ref=da0228654084085b3659ed6b519f66f44b6796ce
```

Wait for admission-webhook-k8s:
```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/da0228654084085b3659ed6b519f66f44b6796ce/examples/use-cases/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

Select node to deploy NSC and NSE:
```bash
NODE=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}')[0])
```

Create forlder for test:
```bash
mkdir example
```

Create customization file:
```bash
cat > example/kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE}

resources: 
- client.yaml
bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=da0228654084085b3659ed6b519f66f44b6796ce

patchesStrategicMerge:
- patch-nse.yaml
EOF
```

Create Client:
```bash
cat > example/client.yaml <<EOF
---
apiVersion: v1
kind: Pod
metadata:
  name: alpine
  labels:
    app: alpine    
  annotations:
    networkservicemesh.io: kernel://icmp-responder/nsm-1
spec:
  containers:
  - name: alpine
    image: alpine:3.15.0
    imagePullPolicy: IfNotPresent
    stdin: true
    tty: true
  nodeSelector:
    kubernetes.io/hostname: ${NODE}
EOF
```

Create NSE patch:
```bash
cat > example/patch-nse.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse-kernel
spec:
  template:
    spec:
      containers:
        - name: nse
          env:
            - name: NSM_CIDR_PREFIX
              value: 172.16.1.100/31
            - name: TELEMETRY
              value: "true"
      nodeSelector:
        kubernetes.io/hostname: ${NODE}
EOF
```

Deploy NSC and NSE:
```bash
kubectl apply -k example
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ${NAMESPACE}
```

Find nsc and nse pods by labels:
```bash
NSC=$(kubectl get pods -l app=alpine -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ${NAMESPACE} -- ping -c 4 172.16.1.101
```

Select forwarder:
```bash
NODES=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}'))
FORWARDER=$(kubectl get pods -l app=forwarder-vpp --field-selector spec.nodeName==${NODES[0]} -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Expose ports to access Jaeger and Prometheus UI:
```bash
kubectl port-forward service/jaeger -n observability 16686:16686&
kubectl port-forward service/prometheus -n observability 9090:9090&
```

Retrieve traces from Jaeger:
```bash
result=$(curl -X GET localhost:16686/api/traces?service=${FORWARDER}&lookback=5m&limit=1)
echo ${result}
echo ${result} | grep -q "forwarder"
```

Replace '-' with '_' in forwarder pod name (Forwarder metric names contain only "_")
```bash
FORWARDER=${FORWARDER//-/_}
```

Retrieve metrics from Prometheus:
```bash
result=$(curl -X GET localhost:9090/api/v1/query?query="${FORWARDER}_server_tx_bytes_sum")
echo ${result}
echo ${result} | grep -q "forwarder"
```

## Cleanup

Delete ns:
```bash
rm -r example
kubectl delete ns ${NAMESPACE}
```

```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl delete mutatingwebhookconfiguration ${WH}
kubectl delete ns nsm-system
```

```bash
kubectl describe ns observability
kubectl delete ns observability
pkill -f "port-forward"
```
