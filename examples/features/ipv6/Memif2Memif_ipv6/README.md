# Test memif to memif connection

This example shows that NSC and NSE on the one node can find each other by ipv6 addresses.

NSC and NSE are using the `memif` mechanism to connect to its local forwarder.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/ipv6/Memif2Memif_ipv6?ref=d4dffa609c30d7c42d0176e5e26f97c61ba92433
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-memif -n ns-memif2memif-ipv6
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-memif -n ns-memif2memif-ipv6
```

Check connectivity:
```bash
result=$(kubectl exec deployments/nsc-memif -n "ns-memif2memif-ipv6" -- vppctl ping ipv6 2001:db8:: repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

Check connectivity:
```bash
result=$(kubectl exec deployments/nse-memif -n "ns-memif2memif-ipv6" -- vppctl ping ipv6 2001:db8::1 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-memif2memif-ipv6
```
