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
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/pss/use-cases/nginx?ref=ae9f9ad2a9b5a154cd37676c4f9649ccfbc42d41
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
