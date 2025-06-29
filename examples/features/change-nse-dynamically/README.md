# Example: NSC changes NSE on Network Service updated

This example shows that NSC can change NSEs if network service has changed during connection without redeploying.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [ipsec mechanism](../../ipsec_mechanism) setup.

## Run

Deploy NSC and two NSEs:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/change-nse-dynamically?ref=8c316c0d2b7b6ce38f9ef2693ae3a076d04a1af1
```

```bash
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/8c316c0d2b7b6ce38f9ef2693ae3a076d04a1af1/examples/features/change-nse-dynamically/blue-netsvc.yaml
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-change-nse-dynamically
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=blue-nse -n ns-change-nse-dynamically
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=green-nse -n ns-change-nse-dynamically
```

Ping from NSC to the blue NSE:
```bash
kubectl exec pods/alpine -n ns-change-nse-dynamically -- ping -c 4 172.16.2.100
```

Ping from the blue NSE to NSC:
```bash
kubectl exec pods/blue-nse -n ns-change-nse-dynamically -- ping -c 4 172.16.2.101
```

Change network service to select green endpoint:
```bash
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/8c316c0d2b7b6ce38f9ef2693ae3a076d04a1af1/examples/features/change-nse-dynamically/green-netsvc.yaml
```

Ping from NSC to the green NSE:
```bash
kubectl exec pods/alpine -n ns-change-nse-dynamically -- ping -c 4 172.16.1.100
```

Ping from the green NSE to NSC:
```bash
kubectl exec pods/green-nse -n ns-change-nse-dynamically -- ping -c 4 172.16.1.101
```

Change network service to select blue endpoint:
```bash
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/8c316c0d2b7b6ce38f9ef2693ae3a076d04a1af1/examples/features/change-nse-dynamically/blue-netsvc.yaml
```

Ping from NSC to the blue NSE:
```bash
kubectl exec pods/alpine -n ns-change-nse-dynamically -- ping -c 4 172.16.2.100
```

Ping from the blue NSE to NSC:
```bash
kubectl exec pods/blue-nse -n ns-change-nse-dynamically -- ping -c 4 172.16.2.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-change-nse-dynamically
```
