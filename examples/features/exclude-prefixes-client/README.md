# Test kernel to kernel connection with excluded prefixes on the client

This example shows kernel to kernel example where we exclude prefixes used by 2 service endpoints on the client side. 

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC, services and NSEs:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/exclude-prefixes-client?ref=e55a5f3b0e9bc062e0235b3daf19447651484373
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-exclude-prefixes-client
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel-1 -n ns-exclude-prefixes-client
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel-2 -n ns-exclude-prefixes-client
```

Ping from NSC to NSE1:
```bash
kubectl exec pods/alpine -n ns-exclude-prefixes-client -- ping -c 4 172.16.1.96
```

Ping from NSC to NSE2:
```bash
kubectl exec pods/alpine -n ns-exclude-prefixes-client -- ping -c 4 172.16.1.98
```

Ping from NSE1 to NSC:
```bash
kubectl exec deployments/nse-kernel-1 -n ns-exclude-prefixes-client -- ping -c 4 172.16.1.97
```

Ping from NSE2 to NSC:
```bash
kubectl exec deployments/nse-kernel-2 -n ns-exclude-prefixes-client -- ping -c 4 172.16.1.99
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-exclude-prefixes-client
```
