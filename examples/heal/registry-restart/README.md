# Test registry restart

This example shows that NSM keeps working after the Registry restart.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/registry-restart/registry-before-death?ref=3c8fd61d1787a8b72cf3fa96c2ca6c2e20981aab
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-registry-restart
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-registry-restart
```

Find nsc and nse pods by labels:
```bash
NSC=$(kubectl get pods -l app=alpine -n ns-registry-restart --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-registry-restart --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-registry-restart -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-registry-restart -- ping -c 4 172.16.1.101
```

Find Registry:
```bash
REGISTRY=$(kubectl get pods -l app=registry -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Restart Registry and wait for it to start:
```bash
kubectl delete pod ${REGISTRY} -n nsm-system
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=registry -n nsm-system
```

Apply a new client:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/registry-restart/registry-after-death?ref=3c8fd61d1787a8b72cf3fa96c2ca6c2e20981aab
```

Wait for a new NSC to start:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine-new -n ns-registry-restart
```

Ping from new NSC to NSE:
```bash
kubectl exec pods/alpine-new -n ns-registry-restart -- ping -c 4 172.16.1.102
```

Ping from NSE to new NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-registry-restart -- ping -c 4 172.16.1.103
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-registry-restart
```
