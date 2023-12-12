# Test kernel to IP to kernel connection

This example shows that NSC and NSE on the different nodes could find and work with each other using IPv6.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `wireguard` mechanism to connect with each other.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/ipv6/Kernel2IP2Kernel_ipv6?ref=811c23f5ce61c3aa001a9403a39c4716e0f23912
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-kernel2ip2kernel-ipv6
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-kernel2ip2kernel-ipv6
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-kernel2ip2kernel-ipv6 -- ping -c 4 2001:db8::
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-kernel2ip2kernel-ipv6 -- ping -c 4 2001:db8::1
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-kernel2ip2kernel-ipv6
```
