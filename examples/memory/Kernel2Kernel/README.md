# Test kernel to kernel connection


This example shows that NSC and NSE on the one node can find each other. 

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.


Diagram:

![NSM kernel2kernel Diagram](./diagram.png "NSM Kernel2Kernel Scheme")


## Requires

Make sure that you have completed steps from [memory](../) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/memory/Kernel2Kernel?ref=ba06535b09d434396268b7e7fb347c184700cd93
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-kernel2kernel
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-kernel2kernel
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-kernel2kernel -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-kernel2kernel -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-kernel2kernel
```
