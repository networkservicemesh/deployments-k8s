# cAdvisor

Contains setup for cAdvisor.

## Run

```bash
kubectl apply -k .
```

```bash
kubectl -n cadvisor --timeout=1m wait pod --for=condition=ready -l app=cadvisor
```

## Cleanup

```bash
kubectl delete -k .
```
