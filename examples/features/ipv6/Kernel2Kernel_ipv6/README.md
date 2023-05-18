# Test kernel to kernel connection


This example shows that NSC and NSE on the one node can find each other by ipv6 addresses.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/ipv6/Kernel2Kernel_ipv6?ref=7ec88cc5e7239a5b0eaed0d5c6bfb95d6c784c93
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-kernel2kernel-ipv6
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-kernel2kernel-ipv6
```

Check connectivity:
```bash
kubectl exec pods/alpine -n ns-kernel2kernel-ipv6 -- ping -c 4 2001:db8::
```

Check connectivity:
```bash
kubectl exec deployments/nse-kernel -n ns-kernel2kernel-ipv6 -- ping -c 4 2001:db8::1
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-kernel2kernel-ipv6
```
