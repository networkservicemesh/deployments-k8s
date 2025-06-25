# Test kernel to Ethernet to kernel connection

This example shows that NSC and NSE on the different nodes could find and work with each other.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `Ethernet` payload to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/Kernel2Ethernet2Kernel?ref=f5d992d5a0210e2356c8f65d4e106e3add88adca
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
