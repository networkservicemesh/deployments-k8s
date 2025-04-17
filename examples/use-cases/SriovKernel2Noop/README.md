# Test SR-IOV kernel connection

This example shows that NSC and NSE can work with each other over the SR-IOV kernel connection.

## Requires

Make sure that you have completed steps from [sriov](../../sriov) setup.

## Run

Deploy ponger:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/SriovKernel2Noop/ponger?ref=eae06c2f26a6b5c32174fbcffd8e2f7656edb886
```

Wait for applications ready:
```bash
kubectl -n ns-sriov-kernel2noop wait --for=condition=ready --timeout=1m pod -l app=ponger
```

Wait for the ponger configuration to be applied:
```bash
kubectl -n ns-sriov-kernel2noop exec deploy/ponger -- ip a | grep "172.16.1.100"
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/SriovKernel2Noop?ref=eae06c2f26a6b5c32174fbcffd8e2f7656edb886
```

Wait for applications ready:
```bash
kubectl -n ns-sriov-kernel2noop wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel
```
```bash
kubectl -n ns-sriov-kernel2noop wait --for=condition=ready --timeout=1m pod -l app=nse-noop
```

Ping from NSC to NSE:
```bash
kubectl -n ns-sriov-kernel2noop exec deployments/nsc-kernel -- ping -c 4 172.16.1.100
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-sriov-kernel2noop
```
