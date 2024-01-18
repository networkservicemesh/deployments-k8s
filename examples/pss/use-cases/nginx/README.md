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
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/pss/use-cases/nginx?ref=65157948a59c0968f1274f01b22cc856b515dffa
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
