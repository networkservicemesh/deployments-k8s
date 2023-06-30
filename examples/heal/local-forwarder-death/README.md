# Test local Forwarder death

This example shows that NSM keeps working after the local Forwarder death.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/local-forwarder-death?ref=a16a960bf22ee0b35862c4686c5701ee76414bff
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-local-forwarder-death
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-local-forwarder-death
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-local-forwarder-death -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-local-forwarder-death -- ping -c 4 172.16.1.101
```

Find nsc node:
```bash
NSC_NODE=$(kubectl get pods -l app=alpine -n ns-local-forwarder-death --template '{{range .items}}{{.spec.nodeName}}{{"\n"}}{{end}}')
```

Find local Forwarder:
```bash
FORWARDER=$(kubectl get pods -l app=forwarder-vpp --field-selector spec.nodeName==${NSC_NODE} -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Remove local Forwarder and wait for a new one to start:
```bash
kubectl delete pod -n nsm-system ${FORWARDER}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=forwarder-vpp --field-selector spec.nodeName==${NSC_NODE} -n nsm-system
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-local-forwarder-death -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-local-forwarder-death -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-local-forwarder-death
```
