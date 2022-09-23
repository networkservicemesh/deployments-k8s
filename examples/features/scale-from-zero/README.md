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

Create test namespace:
```bash
kubectl create ns ns-scale-from-zero
```

Select nodes to deploy NSC and supplier:
```bash
NODES=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints }}{{ .metadata.name }} {{end}}{{end}}'))
NSC_NODE=${NODES[0]}
SUPPLIER_NODE=${NODES[1]}
if [ "$SUPPLIER_NODE" == "" ]; then SUPPLIER_NODE=$NSC_NODE; echo "Only 1 node found, testing that pod is created on the same node is useless"; fi
```

Deploy NSC and supplier:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/scale-from-zero?ref=f10091293371130b17664149e7cde3e82385823f
```

Wait for applications ready:
```bash
kubectl wait -n ns-scale-from-zero --for=condition=ready --timeout=1m pod -l app=nse-supplier-k8s
```
```bash
kubectl wait -n ns-scale-from-zero --for=condition=ready --timeout=1m pod -l app=nsc-kernel
```
```bash
kubectl wait -n ns-scale-from-zero --for=condition=ready --timeout=1m pod -l app=nse-icmp-responder
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pod -n ns-scale-from-zero --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' -l app=nsc-kernel)
NSE=$(kubectl get pod -n ns-scale-from-zero --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' -l app=nse-icmp-responder)
```

Check connectivity:
```bash
kubectl exec $NSC -n ns-scale-from-zero -- ping -c 4 169.254.0.0
```
```bash
kubectl exec $NSE -n ns-scale-from-zero -- ping -c 4 169.254.0.1
```

Check that the NSE spawned on the same node as NSC:
```bash
NSE_NODE=$(kubectl get pod -n ns-scale-from-zero --template '{{range .items}}{{.spec.nodeName}}{{"\n"}}{{end}}' -l app=nse-icmp-responder)
NSC_NODE=$(kubectl get pod -n ns-scale-from-zero --template '{{range .items}}{{.spec.nodeName}}{{"\n"}}{{end}}' -l app=nsc-kernel)
```
```bash
if [ $NSC_NODE == $NSE_NODE ]; then echo "OK"; else echo "different nodes"; false; fi
```

Remove NSC:
```bash
kubectl scale -n ns-scale-from-zero deployment nsc-kernel --replicas=0
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
Delete network service:
```bash
kubectl delete -n nsm-system networkservices.networkservicemesh.io scale-from-zero
```
