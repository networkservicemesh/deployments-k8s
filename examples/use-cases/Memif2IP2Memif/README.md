# Test memif to IP to memif connection

This example shows that NSC and NSE on the different nodes could find and work with each other.

NSC and NSE are using the `memif` mechanism to connect to its local forwarder.
Forwarders are using the `IP` payload to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) or [ipsec mechanism](../../ipsec_mechanism) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/Memif2IP2Memif?ref=4cfdd427b36b11282d313450a44bdace08c04876
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-memif -n ns-memif2ip2memif
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-memif -n ns-memif2ip2memif
```

Ping from NSC to NSE:
```bash
result=$(kubectl exec deployments/nsc-memif -n "ns-memif2ip2memif" -- vppctl ping 172.16.1.100 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

Ping from NSE to NSC:
```bash
result=$(kubectl exec deployments/nse-memif -n "ns-memif2ip2memif" -- vppctl ping 172.16.1.101 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-memif2ip2memif
```
