# Test kernel to Ethernet to kernel connection

This example shows that NSC and NSE on the different nodes could find and work with each other.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `Ethernet` payload to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/Kernel2Ethernet2Kernel?ref=f39f4b398da316ab74e0398a0fd7d5d8c494bc8f
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-kernel2ethernet2kernel
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-kernel2ethernet2kernel
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-kernel2ethernet2kernel -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-kernel2ethernet2kernel -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-kernel2ethernet2kernel
```
