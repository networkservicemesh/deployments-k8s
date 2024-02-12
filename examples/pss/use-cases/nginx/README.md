# Nginx service

This example uses the `restricted` PSS policy for the namespace.
The `restricted` policy requires additional `securityContext` settings as well as not using `hostPath`.

We can see how the client can get connectivity to nginx-server via NSM.
Client pod and server deployment located on different nodes.

## Requires

Make sure that you have completed steps from [PSS](../..).

## Run

Deploy client and nginx-nse
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/pss/use-cases/nginx?ref=cedb4dd79d3abf2686f19a2662e2d8ef857743a4
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=nse-kernel -n ns-nginx
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nettools -n ns-nginx
```

Try to connect from client to nginx service:
```bash
kubectl exec pods/nettools -n ns-nginx -- curl 172.16.1.100:8080 | grep -o "<title>Welcome to nginx"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-nginx
```
