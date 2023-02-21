# Client requests for postgresql service

This example demonstrates how Postgres-client can get connectivity to Postgres-server deployment via NSM.
Client pod and server deployment located on different nodes.


## Requires

Make sure that you have completed steps from [features](../)

## Run

Deploy client and nginx-nse
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/webhook?ref=1716ba572ae06988e041c83516f23d8252b74de8
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=nse-kernel -n ns-webhook
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nettools -n ns-webhook
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=nettools -n ns-webhook --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-webhook --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Try to connect from client to nginx service:
```bash
kubectl exec ${NSC} -n ns-webhook -- curl 172.16.1.100:80 | grep -o "<title>Welcome to nginx!</title>"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-webhook
```
