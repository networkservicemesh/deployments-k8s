# Test kernel to IP to kernel connection

This example shows that NSC and NSE on the different nodes could find and work with each other.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `IP` payload to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [ipsec mechanism](../../ipsec_mechanism) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/multiple-services?ref=28cb182fec9b2e76efd82c6512e650bcaed0809b
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-multiple-services
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel-1 -n ns-multiple-services
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel-2 -n ns-multiple-services
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-multiple-services -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec pods/nse-kernel-1 -n ns-multiple-services -- ping -c 4 172.16.1.101
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-multiple-services -- ping -c 4 172.16.2.100
```

Ping from NSE to NSC:
```bash
kubectl exec pods/nse-kernel-2 -n ns-multiple-services -- ping -c 4 172.16.2.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-multiple-services
```
