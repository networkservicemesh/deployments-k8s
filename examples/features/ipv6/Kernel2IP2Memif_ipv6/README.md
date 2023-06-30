# Test kernel to IP to memif

This example shows that NSC and NSE on the different nodes could find and work with each other using IPv6.

NSC is using the `kernel` mechanism to connect to its local forwarder.
NSE is using the `memif` mechanism to connect to its local forwarder.
Forwarders are using the `wireguard` mechanism to connect with each other.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/ipv6/Kernel2IP2Memif_ipv6?ref=a16a960bf22ee0b35862c4686c5701ee76414bff
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-kernel2ip2memif-ipv6
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-memif -n ns-kernel2ip2memif-ipv6
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-kernel2ip2memif-ipv6 -- ping -c 4 2001:db8::
```

Ping from NSE to NSC:
```bash
result=$(kubectl exec deployments/nse-memif -n "ns-kernel2ip2memif-ipv6" -- vppctl ping 2001:db8::1 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-kernel2ip2memif-ipv6
```
