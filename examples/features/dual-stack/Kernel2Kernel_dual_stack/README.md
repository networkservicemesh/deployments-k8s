# Test kernel to kernel connection


This example shows that NSC and NSE on the one node can find each other by ipv6 addresses.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/dual-stack/Kernel2Kernel_dual_stack?ref=0a4a13ccc33c8dbc29dda9eadd6afb5a187c9644
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-kernel2kernel-dual-stack
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-kernel2kernel-dual-stack
```

Check connectivity:
```bash
kubectl exec pods/alpine -n ns-kernel2kernel-dual-stack -- ping -c 4 2001:db8::
```

Check connectivity:
```bash
kubectl exec deployments/nse-kernel -n ns-kernel2kernel-dual-stack -- ping -c 4 2001:db8::1
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-kernel2kernel-dual-stack -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-kernel2kernel-dual-stack -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-kernel2kernel-dual-stack
```
