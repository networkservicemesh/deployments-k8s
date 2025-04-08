# Floating interdomain memif to IP to memif example

This example shows that NSC can reach NSE registered in floating registry.

NSC and NSE are using the `memif` mechanism to connect to its local forwarder.
Forwarders are using the `IP` payload to connect with each other.

Important points:
- nsc deploys on cluster1 and requests network service from *cluster3*.
- nse deploys on cluster2 and registers itself in *cluster3* with IP payload.


## Requires

Make sure that you have completed steps from [interdomain](../../suites/basic)

## Run

**1. Deploy network service on cluster3**

Deploy NS:
```bash
kubectl --kubeconfig=$KUBECONFIG3 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/usecases/floating_Memif2IP2Memif/cluster3?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

**2. Deploy endpoint on cluster2**

Deploy NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/usecases/floating_Memif2IP2Memif/cluster2?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=2m pod -l app=nse-memif -n ns-floating-memif2ip2memif
```

**2. Deploy client on cluster1**

Deploy NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/usecases/floating_Memif2IP2Memif/cluster1?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=2m pod -l app=nsc-memif -n ns-floating-memif2ip2memif
```

**3. Check connectivity**

Ping from NSC to NSE:
```bash
result=$(kubectl --kubeconfig=$KUBECONFIG1 exec deployments/nsc-memif -n "ns-floating-memif2ip2memif" -- vppctl ping 172.16.1.2 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

Ping from NSE to NSC:
```bash
result=$(kubectl --kubeconfig=$KUBECONFIG2 exec deployments/nse-memif -n "ns-floating-memif2ip2memif" -- vppctl ping 172.16.1.3 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

## Cleanup

Cleanup resources for *cluster1*:
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete ns ns-floating-memif2ip2memif
```

Cleanup resources for *cluster2*:
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete ns ns-floating-memif2ip2memif
```

Cleanup resources for *cluster3*:
```bash
kubectl --kubeconfig=$KUBECONFIG3 delete ns ns-floating-memif2ip2memif
```
