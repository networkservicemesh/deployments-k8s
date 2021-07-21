# cAdvisor

Contains setup for cAdvisor.

## Run

Deploy cAdvisor:
```bash
kubectl apply -k .
```

Wait till cAdvisor pod is created:
```bash
kubectl -n cadvisor --timeout=1m wait pod --for=condition=ready -l app=cadvisor
```

## Cleanup

```bash
kubectl delete -k .
```
