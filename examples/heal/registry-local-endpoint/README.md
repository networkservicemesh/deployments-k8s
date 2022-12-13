# Registry + Local NSE restart

This example shows that NSM keeps working after the Registry and local NSE restart.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-registry-local-endpoint
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/registry-local-endpoint/nse-first?ref=60af7a03af9d7d020e5e17dcbb822c7bd6a77c02
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-registry-local-endpoint
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-registry-local-endpoint
```

Find nsc and nse pods by labels:
```bash
NSC=$(kubectl get pods -l app=alpine -n ns-registry-local-endpoint --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-registry-local-endpoint --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-registry-local-endpoint -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-registry-local-endpoint -- ping -c 4 172.16.1.101
```

Find Registry:
```bash
REGISTRY=$(kubectl get pods -l app=registry -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Restart Registry and NSE:
```bash
kubectl delete pod ${REGISTRY} -n nsm-system
```
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/registry-local-endpoint/nse-second?ref=60af7a03af9d7d020e5e17dcbb822c7bd6a77c02
```

Waiting for new ones:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=registry -n nsm-system
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -l version=new -n ns-registry-local-endpoint
```

Find new NSE pod:
```bash
NEW_NSE=$(kubectl get pods -l app=nse-kernel -l version=new -n ns-registry-local-endpoint --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to new NSE:
```bash
kubectl exec ${NSC} -n ns-registry-local-endpoint -- ping -c 4 172.16.1.102
```

Ping from new NSE to NSC:
```bash
kubectl exec ${NEW_NSE} -n ns-registry-local-endpoint -- ping -c 4 172.16.1.103
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-registry-local-endpoint
```
