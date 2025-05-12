# Test kernel to ethernet to kernel connection

This example shows that NSC and NSE on the different clusters could find and work with each other.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [interdomain](../../suites/basic)

## Run

**1. Deploy endpoint on cluster2**

Deploy NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/usecases/interdomain_Kernel2Ethernet2Kernel/cluster2?ref=v1.14.5
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-interdomain-kernel2ethernet2kernel
```

**2. Deploy client on cluster1**

Deploy client:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/usecases/interdomain_Kernel2Ethernet2Kernel/cluster1?ref=v1.14.5
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=5m pod -l app=alpine -n ns-interdomain-kernel2ethernet2kernel
```

**3. Check connectivity**

Ping from NSC to NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/alpine -n ns-interdomain-kernel2ethernet2kernel -- ping -c 4 172.16.1.2
```

Ping from NSE to NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec deployments/nse-kernel -n ns-interdomain-kernel2ethernet2kernel -- ping -c 4 172.16.1.3
```

## Cleanup

Cleanup resources for *cluster1*:
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete ns ns-interdomain-kernel2ethernet2kernel
```

Cleanup resources for *cluster2*:
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete ns ns-interdomain-kernel2ethernet2kernel
```
