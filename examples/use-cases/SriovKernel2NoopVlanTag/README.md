# Test SR-IOV kernel VLAN tagged connection

**_Note: 802.1Q must be enabled on your cluster_**

This example shows that NSC and NSE can work with each other over the SR-IOV kernel connection.

## Requires

Make sure that you have completed steps from [sriov](../../sriov_vlantag) setup.

## Run

Deploy ponger:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/SriovKernel2NoopVlanTag/ponger?ref=8e12a3fa8616259f3da70b67fa7ae1fe6e0e9f0e
```

Wait for applications ready:
```bash
kubectl -n ns-sriov-kernel2noop-vlantag wait --for=condition=ready --timeout=1m pod -l app=ponger
```

Wait for the ponger configuration to be applied:
```bash
kubectl -n ns-sriov-kernel2noop-vlantag exec deploy/ponger -- ip a | grep "172.16.1.100"
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/SriovKernel2NoopVlanTag?ref=8e12a3fa8616259f3da70b67fa7ae1fe6e0e9f0e
```

Wait for applications ready:
```bash
kubectl -n ns-sriov-kernel2noop-vlantag wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel
```
```bash
kubectl -n ns-sriov-kernel2noop-vlantag wait --for=condition=ready --timeout=1m pod -l app=nse-noop
```

Ping from NSC to NSE:
```bash
kubectl -n ns-sriov-kernel2noop-vlantag exec deployments/nsc-kernel -- ping -c 4 172.16.1.100
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-sriov-kernel2noop-vlantag
```
