# Test kernel to Ethernet to memif

This example shows that NSC and NSE on the different nodes could find and work with each other.

NSC is using the `kernel` mechanism to connect to its local forwarder.
NSE is using the `memif` mechanism to connect to its local forwarder.
Forwarders are using the `Ethernet` payload to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/Kernel2Ethernet2Memif?ref=12d90ac8ebe5905d678f2f20e16c2c42f6062af8
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-kernel2ethernet2memif
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-memif -n ns-kernel2ethernet2memif
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-kernel2ethernet2memif -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
result=$(kubectl exec deployments/nse-memif -n "ns-kernel2ethernet2memif" -- vppctl ping 172.16.1.101 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-kernel2ethernet2memif
```
