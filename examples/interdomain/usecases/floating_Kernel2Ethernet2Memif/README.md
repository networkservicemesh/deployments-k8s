# Floating interdomain kernel to Ethernet to memif example

This example shows that NSC can reach NSE registered in floating registry.

NSC is using the `kernel` mechanism to connect to its local forwarder.
NSE is using the `memif` mechanism to connect to its local forwarder.
Forwarders are using the `Ethernet` payload to connect with each other.

Important points:
- nsc deploys on cluster1 and requests network service from *cluster3*.
- nse deploys on cluster2 and registers itself in *cluster3* with IP payload.

## Requires

Make sure that you have completed steps from [interdomain](../../suites/basic)

## Run

**1. Deploy network service on cluster3**

Deploy NS:
```bash
kubectl --kubeconfig=$KUBECONFIG3 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/usecases/floating_Kernel2Ethernet2Memif/cluster3?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

**2. Deploy endpoint on cluster2**

Deploy NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/usecases/floating_Kernel2Ethernet2Memif/cluster2?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=2m pod -l app=nse-memif -n ns-floating-kernel2ethernet2memif
```

**2. Deploy client on cluster1**

Deploy NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/usecases/floating_Kernel2Ethernet2Memif/cluster1?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=5m pod -l app=alpine -n ns-floating-kernel2ethernet2memif
```

**3. Check connectivity**

```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/alpine -n ns-floating-kernel2ethernet2memif -- ping -c 4 172.16.1.2
```

Ping from NSE to NSC:
```bash
result=$(kubectl --kubeconfig=$KUBECONFIG2 exec deployments/nse-memif -n "ns-floating-kernel2ethernet2memif" -- vppctl ping 172.16.1.3 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

## Cleanup

Cleanup resources for *cluster1*:
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete ns ns-floating-kernel2ethernet2memif
```

Cleanup resources for *cluster2*:
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete ns ns-floating-kernel2ethernet2memif
```

Cleanup resources for *cluster3*:
```bash
kubectl --kubeconfig=$KUBECONFIG3 delete ns ns-floating-kernel2ethernet2memif
```
