# Test Smart VF connection

This example shows that NSC and NSE can work with each other over the SmartVF dual mode (kernel or dpdk) connection.

## Requires

Make sure that you have completed steps from [ovs](../../ovs) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/SmartVF2SmartVF?ref=058a1a30df6bb587e10a56bf96dad7be3d4e9c49
```

Wait for applications ready:
```bash
kubectl -n ns-smartvf2smartvf wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel
```
```bash
kubectl -n ns-smartvf2smartvf wait --for=condition=ready --timeout=1m pod -l app=nse-kernel
```

Ping from NSC to NSE:
```bash
kubectl -n ns-smartvf2smartvf exec deployments/nsc-kernel -- ping -c 4 172.16.1.100
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-smartvf2smartvf
```
