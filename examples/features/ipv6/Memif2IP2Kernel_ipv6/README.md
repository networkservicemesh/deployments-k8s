# Test memif to IP to kernel connection

This example shows that NSC and NSE on the different nodes could find and work with each other using IPv6.


NSC is using the `memif` mechanism to connect to its local forwarder.
NSE is using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `wireguard` mechanism to connect with each other.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/ipv6/Memif2IP2Kernel_ipv6?ref=f432bc616ff6d549c8003ea90a40144a8fb59288
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-memif -n ns-memif2ip2kernel-ipv6
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-memif2ip2kernel-ipv6
```

Ping from NSC to NSE:
```bash
result=$(kubectl exec deployments/nsc-memif -n "ns-memif2ip2kernel-ipv6" -- vppctl ping 2001:db8:: repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-memif2ip2kernel-ipv6 -- ping -c 4 2001:db8::1
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-memif2ip2kernel-ipv6
```
