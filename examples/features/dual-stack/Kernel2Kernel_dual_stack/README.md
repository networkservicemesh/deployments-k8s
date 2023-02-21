# Test kernel to kernel connection


This example shows that NSC and NSE on the one node can find each other by ipv6 addresses.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/dual-stack/Kernel2Kernel_dual_stack?ref=f53d735b773aba39ce2909d642e43bf903f57c14
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-kernel2kernel-dual-stack
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-kernel2kernel-dual-stack
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=alpine -n ns-kernel2kernel-dual-stack --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-kernel2kernel-dual-stack --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Check connectivity:
```bash
kubectl exec ${NSC} -n ns-kernel2kernel-dual-stack -- ping -c 4 2001:db8::
```

Check connectivity:
```bash
kubectl exec ${NSE} -n ns-kernel2kernel-dual-stack -- ping -c 4 2001:db8::1
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-kernel2kernel-dual-stack -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-kernel2kernel-dual-stack -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-kernel2kernel-dual-stack
```
