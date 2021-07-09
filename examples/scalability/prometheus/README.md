# Prometheus

Contains setup for Prometheus.

## Requires

- [cAdvisor](../cadvisor)
- [kube-state-metrics](../kube_state_metrics)

## Run

1. Create ns for deployments:
```bash
kubectl apply -k .
```

```bash
kubectl -n monitoring --timeout=1m wait pod --for=condition=ready $(kubectl -n monitoring get pod --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' -l app=prometheus-server)
```

## Cleanup
Remove Prometheus:
```bash
kubectl delete -k .
```
