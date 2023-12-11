# NSM interdomain setup


This example simply show how can be deployed and configured two NSM on different clusters

## Run

Create basic NSM deployment on cluster 1:

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm/cluster1?ref=f20771a355dff1f5b9a85f1a1a236c3f6b13bc41
```

Create basic NSM deployment on cluster 2:

```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm/cluster2?ref=f20771a355dff1f5b9a85f1a1a236c3f6b13bc41
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
kubectl --kubeconfig=$KUBECONFIG1 delete -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm/cluster1?ref=f20771a355dff1f5b9a85f1a1a236c3f6b13bc41
kubectl --kubeconfig=$KUBECONFIG2 delete -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm/cluster2?ref=f20771a355dff1f5b9a85f1a1a236c3f6b13bc41
```
