# Floating interdomain kernel to IP to kernel example

This example shows that NSC can reach NSE registered in floating registry.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `wireguard` mechanism to connect with each other.


Important points:
- nsc deploys on cluster1 and requests network service from *cluster3*.
- nse deploys on cluster2 and registers itself in *cluster3* with IP payload.


## Requires

Make sure that you have completed steps from [interdomain](../../)

## Run

**1. Deploy network service on cluster3**

Deploy NS:
```bash
kubectl --kubeconfig=$KUBECONFIG3 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_Kernel2IP2Kernel/cluster3?ref=328b448a5d21b92499c0f090cfb27700d0274077
```

**2. Deploy endpoint on cluster2**

Deploy NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_Kernel2IP2Kernel/cluster2?ref=328b448a5d21b92499c0f090cfb27700d0274077
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-floating-kernel2ip2kernel
```

**2. Deploy client on cluster1**

Deploy NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_Kernel2IP2Kernel/cluster1?ref=328b448a5d21b92499c0f090cfb27700d0274077
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=5m pod -l app=alpine -n ns-floating-kernel2ip2kernel
```

**3. Check connectivity**

```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/alpine -n ns-floating-kernel2ip2kernel -- ping -c 4 172.16.1.2
```

Ping from NSE to NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec deployments/nse-kernel -n ns-floating-kernel2ip2kernel -- ping -c 4 172.16.1.3
```

## Cleanup

Cleanup resources for *cluster1*:
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete ns ns-floating-kernel2ip2kernel
```

Cleanup resources for *cluster2*:
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete ns ns-floating-kernel2ip2kernel
```

Cleanup resources for *cluster3*:
```bash
kubectl --kubeconfig=$KUBECONFIG3 delete ns ns-floating-kernel2ip2kernel
```
