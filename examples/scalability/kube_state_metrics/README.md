# Prometheus

Contains setup for cAdvisor.

## Run

```bash
kubectl apply -k .
```

```bash
kubectl -n kube-system --timeout=1m wait pod --for=condition=ready -l app=kube-state-metrics
```

## Cleanup

```bash
kubectl delete -k .
```
