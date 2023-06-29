# Local Forwarder + Remote Forwarder restart

This example shows that NSM keeps working after the local Forwarder + remote Forwarder restarts.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/local-forwarder-remote-forwarder?ref=d67f76693e213ede558e8453c049c8f4ba04e825
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-local-forwarder-remote-forwarder
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-local-forwarder-remote-forwarder
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-local-forwarder-remote-forwarder -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-local-forwarder-remote-forwarder -- ping -c 4 172.16.1.101
```

Find nsc and nse nodes:
```bash
NSC_NODE=$(kubectl get pods -l app=alpine -n ns-local-forwarder-remote-forwarder --template '{{range .items}}{{.spec.nodeName}}{{"\n"}}{{end}}')
NSE_NODE=$(kubectl get pods -l app=nse-kernel -n ns-local-forwarder-remote-forwarder --template '{{range .items}}{{.spec.nodeName}}{{"\n"}}{{end}}')
```

Find local Forwarder:
```bash
FORWARDER1=$(kubectl get pods -l app=forwarder-vpp --field-selector spec.nodeName==${NSC_NODE} -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Find remote Forwarder:
```bash
FORWARDER2=$(kubectl get pods -l app=forwarder-vpp --field-selector spec.nodeName==${NSE_NODE} -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Restart local and remote Forwarders:
```bash
kubectl delete pod ${FORWARDER1} -n nsm-system
```
```bash
kubectl delete pod ${FORWARDER2} -n nsm-system 
```

Waiting for new ones:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=forwarder-vpp --field-selector spec.nodeName==${NSC_NODE} -n nsm-system
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=forwarder-vpp --field-selector spec.nodeName==${NSE_NODE} -n nsm-system
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-local-forwarder-remote-forwarder -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-local-forwarder-remote-forwarder -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-local-forwarder-remote-forwarder
```
