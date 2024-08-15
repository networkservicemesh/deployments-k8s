# Test memif to memif connection


This example shows that NSC and NSE on the one node can find each other.

NSC and NSE are using the `memif` mechanism to connect to its local forwarder.

## Requires

Make sure that you have completed steps from [memory](../) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/memory/Memif2Memif?ref=39c4383fe8ccc8d2246f08317861e6466a9d5ab0
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-memif -n ns-memif2memif
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-memif -n ns-memif2memif
```

Check connectivity:
```bash
result=$(kubectl exec deployments/nsc-memif -n ns-memif2memif -- vppctl ping 172.16.1.100 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

Check connectivity:
```bash
result=$(kubectl exec deployments/nse-memif -n ns-memif2memif -- vppctl ping 172.16.1.101 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-memif2memif
```
