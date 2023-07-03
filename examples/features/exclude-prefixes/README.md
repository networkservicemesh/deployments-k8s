# Test kernel to kernel connection with excluded prefixes

This example shows kernel to kernel example where we excluded 2 prefixes from provided IP prefix range. 

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create config map with excluded prefixes
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/exclude-prefixes/configmap?ref=cd08554366b1c00f24a45489d09e2247e069aa5a
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/exclude-prefixes?ref=cd08554366b1c00f24a45489d09e2247e069aa5a
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
kubectl exec pods/alpine -n ns-exclude-prefixes -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-exclude-prefixes -- ping -c 4 172.16.1.103
```

## Cleanup

Delete ns:
```bash
kubectl delete configmap excluded-prefixes-config
kubectl delete ns ns-exclude-prefixes
```
