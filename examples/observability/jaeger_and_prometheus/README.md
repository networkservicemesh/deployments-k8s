# Jaeger and Prometheus Example

This example demonstrates how to setup Open Telemetry Collector with Jaeger and Prometheus to gather telemetry data from NSM components.
[OpenTelemetry](https://opentelemetry.io/) is a collection of tools, APIs, and SDKs. It is used to instrument, generate, collect, and export telemetry data (metrics, logs, and traces) to help you analyze your software’s performance and behavior.

## Requires

- [Basic NSM setup](../nsm_system/)

## Run
Apply Jaeger, Prometheus and OpenTelemetry Collector:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/observability/jaeger_and_prometheus?ref=7850f88cda6ee4abd5be8756c3c5de3e97d40bec
```

Wait for OpenTelemetry Collector POD status ready:
```bash
kubectl wait -n observability --timeout=1m --for=condition=ready pod -l app=opentelemetry
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/observability/jaeger_and_prometheus/example?ref=7850f88cda6ee4abd5be8756c3c5de3e97d40bec
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-jaeger-and-prometheus
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-jaeger-and-prometheus
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-jaeger-and-prometheus -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-jaeger-and-prometheus -- ping -c 4 172.16.1.101
```

Select forwarder:
```bash
NSE_NODE=$(kubectl get pods -l app=nse-kernel -n ns-jaeger-and-prometheus --template '{{range .items}}{{.spec.nodeName}}{{"\n"}}{{end}}')
FORWARDER=$(kubectl get pods -l app=forwarder-vpp --field-selector spec.nodeName==${NSE_NODE} -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
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
result=$(curl -X GET localhost:9090/api/v1/query?query="${FORWARDER}_server_tx_bytes")
echo ${result}
echo ${result} | grep -q "forwarder"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-jaeger-and-prometheus
```

```bash
kubectl describe pods -n observability
kubectl delete ns observability
pkill -f "port-forward"
```
