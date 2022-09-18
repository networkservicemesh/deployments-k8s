# NSC as external docker container

In this example we create a connection between an external NSC and the kubernetes cluster.
NSC requests the service and creates the required interface on the monolith:

![NSC  k8s](./docker-NSC_k8s.png "NSC + k8s")

## Requires

- [Docker container](./docker)
- [DNS](./dns)
- [spire](./spire)

## Includes

- [Kernel to Wireguard to Kernel Connection](./usecases/Kernel2Wireguard2Kernel)

## Run

```bash
kubectl create ns nsm-system
```

Apply NSM resources for basic tests:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/k8s_monolith/configuration/cluster?ref=637a75f55ef97ec758d3c175a3a3a8a1f6882c42
```

Wait for registry service exposing:
```bash
kubectl get services registry -n nsm-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

## Cleanup

To free resources follow the next command:
```bash
kubectl delete ns nsm-system
```
