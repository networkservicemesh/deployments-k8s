# NSC as external docker container

In this example we create a connection between an external NSC and the kubernetes cluster.
NSC requests the service and creates the required interface on the monolith:

![NSC  k8s](./docker-NSC_k8s.png "NSC + k8s")

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
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/k8s_monolith/configuration/cluster?ref=7af3a87ba35c79804de4324f45fd7e409e1cb5eb
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
