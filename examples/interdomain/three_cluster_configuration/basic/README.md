# Interdomain basic NSM setup

In this example, NSM-system is deployed on three clusters. The third cluster is used as a floating-registry

## Requires

- [Load balancer](../../three_cluster_configuration/loadbalancer)
- [Interdomain DNS](../../three_cluster_configuration/dns)
- Interdomain spire
    - [Spire on first cluster](../../../spire/cluster1)
    - [Spire on second cluster](../../../spire/cluster2)
    - [Spire on third cluster](../../../spire/cluster3)
    - [Spiffe Federation](../../three_cluster_configuration/spiffe_federation)

## Run

Apply NSM resources for cluster1:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/three_cluster_configuration/basic/cluster1?ref=c2aa9e7e66a98b5efbb22f5e0717682ed8856f35
```

Apply NSM resources for cluster2:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/three_cluster_configuration/basic/cluster2?ref=c2aa9e7e66a98b5efbb22f5e0717682ed8856f35
```

Apply NSM resources for cluster3:
```bash
kubectl --kubeconfig=$KUBECONFIG3 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/three_cluster_configuration/basic/cluster3?ref=c2aa9e7e66a98b5efbb22f5e0717682ed8856f35
```

Wait for nsmgr-proxy-service exposing:
```bash
kubectl --kubeconfig=$KUBECONFIG1 get services nsmgr-proxy -n nsm-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 get services nsmgr-proxy -n nsm-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

Wait for admission-webhook-k8s:
```bash
WH=$(kubectl --kubeconfig=$KUBECONFIG1 get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```
```bash
WH=$(kubectl --kubeconfig=$KUBECONFIG2 get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```

Wait for registry exposing:
```bash
kubectl --kubeconfig=$KUBECONFIG3 get services registry -n nsm-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

## Cleanup

To free resources follow the next command:

```bash
kubectl --kubeconfig=$KUBECONFIG1 delete mutatingwebhookconfiguration nsm-mutating-webhook
kubectl --kubeconfig=$KUBECONFIG1 delete ns nsm-system
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete mutatingwebhookconfiguration nsm-mutating-webhook
kubectl --kubeconfig=$KUBECONFIG2 delete ns nsm-system
```
```bash
kubectl --kubeconfig=$KUBECONFIG3 delete ns nsm-system
```
