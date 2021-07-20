# kube-state-metrics

Contains setup for kube-state-metrics.

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
