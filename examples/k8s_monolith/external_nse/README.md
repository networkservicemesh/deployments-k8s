# vl3-NSE as external docker container

In this example we need to create a connection between the kubernetes cluster and an external NSE. All clients connected to this endpoint will be on the same vl3-network.
This NSE creates the required interface on the monolith:

![NSM  k8s_monolith](./k8s_monolith.png "NSM k8s + monolith")

## Requires

- [LoadBalancer](../configuration/loadbalancer)
- [Docker container](./docker)
- [DNS](./dns)
- Spire
    - [Spire in k8s](../../spire/single_cluster)
    - [Spiffe Federation](./spiffe_federation)

## Run

Apply NSM resources for basic tests:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/k8s_monolith/configuration/cluster?ref=c2aa9e7e66a98b5efbb22f5e0717682ed8856f35
```

Wait for admission-webhook-k8s:
```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```

Wait for registry service exposing:
```bash
kubectl get services registry -n nsm-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

## Includes

- [Kernel to IP to Kernel Connection](./usecases/Kernel2IP2Kernel)

## Cleanup

To free resources follow the next command:
```bash
kubectl delete mutatingwebhookconfiguration nsm-mutating-webhook
kubectl delete ns nsm-system
```
