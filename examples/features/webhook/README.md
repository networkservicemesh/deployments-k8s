# Client requests for postgresql service

This example demonstrates how Postgres-client can get connectivity to Postgres-server deployment via NSM.
Client pod and server deployment located on different nodes.


## Requires

Make sure that you have completed steps from [features](../)

## Run

Deploy client and nginx-nse
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/webhook?ref=bc2c59b2741c9b67b3afe4f67f28d1b7b2ad2112
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=nse-kernel -n ns-webhook
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nettools -n ns-webhook
```

Try to connect from client to nginx service:
```bash
kubectl exec pods/nettools -n ns-webhook -- curl 172.16.1.100:80 | grep -o "<title>Welcome to nginx!</title>"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-webhook
```
