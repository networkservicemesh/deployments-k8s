# Test kernel to IP to kernel connection

This example shows that NSC and NSE on the different nodes could find and work with each other using IPv6.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `wireguard` mechanism to connect with each other.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/dual-stack/Kernel2IP2Kernel_dual_stack?ref=51f4f5c1b9ae1f00c9e6bc7c3b7577912f1da10a
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-kernel2ip2kernel-dual-stack
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-kernel2ip2kernel-dual-stack
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-kernel2ip2kernel-dual-stack -- ping -c 4 2001:db8::
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-kernel2ip2kernel-dual-stack -- ping -c 4 2001:db8::1
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-kernel2ip2kernel-dual-stack -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-kernel2ip2kernel-dual-stack -- ping -c 4 172.16.1.101
```
## Cleanup

Delete ns:
```bash
kubectl delete ns ns-kernel2ip2kernel-dual-stack
```
