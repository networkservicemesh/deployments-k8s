# Interdomain basic NSM setup

In this example, NSM-system is deployed on two clusters.

## Requires

- [Load balancer](../../two_cluster_configuration/loadbalancer)
- [Interdomain DNS](../../two_cluster_configuration/dns)
- Interdomain spire
    - [Spire on first cluster](../../../spire/cluster1)
    - [Spire on second cluster](../../../spire/cluster2)
    - [Spiffe Federation](../../two_cluster_configuration/spiffe_federation)

## Run

Apply NSM resources for cluster1:

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/two_cluster_configuration/basic/cluster1?ref=e87e361aed1f3f86078254714ab75d91a26a69f1
```

Apply NSM resources for cluster2:

```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/two_cluster_configuration/basic/cluster2?ref=e87e361aed1f3f86078254714ab75d91a26a69f1
```

Wait for NSM admission webhook on cluster 1:

```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=1m pod -n nsm-system -l app=admission-webhook-k8s
```

Wait for NSM admission webhook on cluster 2:

```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=1m pod -n nsm-system -l app=admission-webhook-k8s
```

## Cleanup

To free resources follow the next commands:

```bash
kubectl --kubeconfig=$KUBECONFIG1 delete mutatingwebhookconfiguration nsm-mutating-webhook
kubectl --kubeconfig=$KUBECONFIG1 delete ns nsm-system
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete mutatingwebhookconfiguration nsm-mutating-webhook
kubectl --kubeconfig=$KUBECONFIG2 delete ns nsm-system
```
