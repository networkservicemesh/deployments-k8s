# Test kernel to kernel connection with excluded prefixes

This example shows kernel to kernel example where we excluded 2 prefixes from provided IP prefix range. 

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create config map with excluded prefixes
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/exclude-prefixes/configmap?ref=074947f2e902b17de98c9410c96cc09d3208e15a
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/exclude-prefixes?ref=074947f2e902b17de98c9410c96cc09d3208e15a
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-exclude-prefixes
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-exclude-prefixes
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-exclude-prefixes -- ping -c 4 172.16.1.200
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-exclude-prefixes -- ping -c 4 172.16.1.203
```

## Cleanup

Delete ns:
```bash
kubectl delete configmap excluded-prefixes-config
kubectl delete ns ns-exclude-prefixes
```
