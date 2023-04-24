# Test kernel to kernel connection with excluded prefixes

This example shows kernel to kernel example where we excluded 2 prefixes from provided IP prefix range. 

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create config map with excluded prefixes
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/exclude-prefixes/configmap?ref=61a4eda12e542e6f39ad76c64be33a09e8db7f34
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/exclude-prefixes?ref=61a4eda12e542e6f39ad76c64be33a09e8db7f34
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
