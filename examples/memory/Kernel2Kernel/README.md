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
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/memory/Kernel2Kernel?ref=f39f4b398da316ab74e0398a0fd7d5d8c494bc8f
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
