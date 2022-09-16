# Jaeger and Prometheus Example

This example demonstrates how to setup Open Telemetry Collector with Jaeger and Prometheus to gather telemetry data from NSM components.
[OpenTelemetry](https://opentelemetry.io/) is a collection of tools, APIs, and SDKs. It is used to instrument, generate, collect, and export telemetry data (metrics, logs, and traces) to help you analyze your software’s performance and behavior.

## Run
Apply Jaeger, Prometheus and OpenTelemetry Collector:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/observability/jaeger-and-prometheus?ref=e0a47eb412e15e51afec1f303f87e7cc2cc31b09
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
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/observability/jaeger-and-prometheus/nsm-system?ref=e0a47eb412e15e51afec1f303f87e7cc2cc31b09
```

Wait for admission-webhook-k8s:
```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```

Create test namespace:
```bash
kubectl create ns ns-jaeger-and-prometheus
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/observability/jaeger-and-prometheus/example?ref=e0a47eb412e15e51afec1f303f87e7cc2cc31b09
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-jaeger-and-prometheus
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-jaeger-and-prometheus
```

Find nsc and nse pods by labels:
```bash
NSC=$(kubectl get pods -l app=alpine -n ns-jaeger-and-prometheus --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-jaeger-and-prometheus --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-jaeger-and-prometheus -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-jaeger-and-prometheus -- ping -c 4 172.16.1.101
```

Select forwarder:
```bash
NODES=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}'))
FORWARDER=$(kubectl get pods -l app=forwarder-vpp --field-selector spec.nodeName==${NODES[0]} -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Expose ports to access Jaeger and Prometheus UI:
```bash
kubectl port-forward service/jaeger -n observability 16686:16686 2>&1 > /dev/null &
kubectl port-forward service/prometheus -n observability 9090:9090 2>&1 > /dev/null &
```

Retrieve traces from Jaeger:
```bash
result=$(curl -X GET localhost:16686/api/traces?service=${FORWARDER}&lookback=5m&limit=1)
echo ${result}
echo ${result} | grep -q "forwarder"
```

Replace `-` with `_` in forwarder pod name (Forwarder metric names contain only `_`)
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
kubectl delete ns ns-jaeger-and-prometheus
```

```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl delete mutatingwebhookconfiguration ${WH}
kubectl delete ns nsm-system
```

```bash
kubectl describe pods -n observability
kubectl delete ns observability
pkill -f "port-forward"
```
