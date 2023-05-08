# Test automatic scale from zero

This example shows that NSEs can be created on the fly on NSC requests.
This allows effective scaling for endpoints.
The requested endpoint will be automatically spawned on the same node as NSC (see step 12),
allowing the best performance for connectivity.

Here we are using an endpoint that automatically shuts down
when it has no active connection for specified time.
We are using very short timeout for the purpose of the test: 15 seconds.

We are only using one client in this test,
so removing it (see step 13) will cause the NSE to shut down.

Supplier watches for endpoints it created
and clears endpoints that finished their work,
thus saving cluster resources (see step 14).

## Run

Deploy NSC and supplier:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/scale-from-zero?ref=79f377661f79a606d728d5ab0a71366142a0e8d0
```

Wait for applications ready:
```bash
kubectl wait -n ns-scale-from-zero --for=condition=ready --timeout=1m pod -l app=nse-supplier-k8s
```
```bash
kubectl wait -n ns-scale-from-zero --for=condition=ready --timeout=1m pod -l app=alpine
```
```bash
kubectl wait -n ns-scale-from-zero --for=condition=ready --timeout=1m pod -l app=nse-icmp-responder
```

Find NSE pod by label:
```bash
NSE=$(kubectl get pod -n ns-scale-from-zero --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' -l app=nse-icmp-responder)
```

Check connectivity:
```bash
kubectl exec pods/alpine -n ns-scale-from-zero -- ping -c 4 169.254.0.0
```
```bash
kubectl exec $NSE -n ns-scale-from-zero -- ping -c 4 169.254.0.1
```

Check that the NSE spawned on the same node as NSC:
```bash
NSE_NODE=$(kubectl get pod -n ns-scale-from-zero --template '{{range .items}}{{.spec.nodeName}}{{"\n"}}{{end}}' -l app=nse-icmp-responder)
NSC_NODE=$(kubectl get pod -n ns-scale-from-zero --template '{{range .items}}{{.spec.nodeName}}{{"\n"}}{{end}}' -l app=alpine)
```
```bash
if [ $NSC_NODE == $NSE_NODE ]; then echo "OK"; else echo "different nodes"; false; fi
```

Remove NSC:
```bash
kubectl delete pod -n ns-scale-from-zero alpine
```

Wait for the NSE pod to be deleted:
```bash
kubectl wait -n ns-scale-from-zero --for=delete --timeout=1m pod -l app=nse-icmp-responder
```

## Cleanup

Delete namespace:
```bash
kubectl delete ns ns-scale-from-zero
```
