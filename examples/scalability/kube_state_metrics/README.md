# kube-state-metrics

Contains setup for kube-state-metrics.

## Run

Deploy kube-state-metrics:
```bash
kubectl apply -k .
```

Wait till kube-state-metrics is up and running:
```bash
kubectl -n kube-system --timeout=1m wait pod --for=condition=ready -l app=kube-state-metrics
```

## Cleanup

```bash
kubectl delete -k .
```
