# Test kernel to IP to kernel connection

This example shows that NSC and NSE on the different nodes could find and work with each other using IPv6.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `wireguard` mechanism to connect with each other.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/ipv6/Kernel2IP2Kernel_ipv6?ref=ba3e7e525c9b22d207b9ba376f7cfee3aaf453dc
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
