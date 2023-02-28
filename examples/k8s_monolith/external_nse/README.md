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

## Includes

- [Kernel to Wireguard to Kernel Connection](./usecases/Kernel2Wireguard2Kernel)

## Run

Apply NSM resources for basic tests:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/k8s_monolith/configuration/cluster?ref=447e6e612bc777058f9a7a82fff1a449e078c1f5
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

## Cleanup

To free resources follow the next command:
```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl delete mutatingwebhookconfiguration ${WH}
kubectl delete ns nsm-system
```
