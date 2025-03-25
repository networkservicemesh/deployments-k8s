# Client requests for nginx service

This example demonstrates how the client can get connectivity to the nginx-server via NSM.
Client pod and server deployment located on different nodes.


## Requires

Make sure that you have completed steps from [features](../)

## Run

Deploy client and nginx-nse
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/webhook?ref=8fd6c96257f39ca82d7f0445cc6e3aad9ef50a1a
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
