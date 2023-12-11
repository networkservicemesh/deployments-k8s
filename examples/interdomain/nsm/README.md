# NSM interdomain setup


This example simply show how can be deployed and configured two NSM on different clusters

## Run

Create basic NSM deployment on cluster 1:

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm/cluster1?ref=bf1c87a3ac49bbeaa4fae1cd0da33528039e591c
```

Create basic NSM deployment on cluster 2:

```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm/cluster2?ref=bf1c87a3ac49bbeaa4fae1cd0da33528039e591c
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

Cleanup NSM
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm/cluster1?ref=bf1c87a3ac49bbeaa4fae1cd0da33528039e591c
kubectl --kubeconfig=$KUBECONFIG2 delete -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm/cluster2?ref=bf1c87a3ac49bbeaa4fae1cd0da33528039e591c
```
