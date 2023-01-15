# Local NSMgr + Remote NSMgr restart

This example shows that NSM keeps working after the local NSMgr + remote NSMgr restart.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-local-nsmgr-remote-nsmgr
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/local-nsmgr-remote-nsmgr?ref=ee3086de687220cee7d79eddaf5465a92cdbd298
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-local-nsmgr-remote-nsmgr
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-local-nsmgr-remote-nsmgr
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=alpine -n ns-local-nsmgr-remote-nsmgr --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-local-nsmgr-remote-nsmgr --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-local-nsmgr-remote-nsmgr -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-local-nsmgr-remote-nsmgr -- ping -c 4 172.16.1.101
```

Find nsc and nse nodes:
```bash
NSC_NODE=$(kubectl get pods -l app=alpine -n ns-local-nsmgr-remote-nsmgr --template '{{range .items}}{{.spec.nodeName}}{{"\n"}}{{end}}')
NSE_NODE=$(kubectl get pods -l app=nse-kernel -n ns-local-nsmgr-remote-nsmgr --template '{{range .items}}{{.spec.nodeName}}{{"\n"}}{{end}}')
```

Find local NSMgr pod:
```bash
NSMGR1=$(kubectl get pods -l app=nsmgr --field-selector spec.nodeName==${NSC_NODE} -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Find remote NSMgr pod:
```bash
NSMGR2=$(kubectl get pods -l app=nsmgr --field-selector spec.nodeName==${NSE_NODE} -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Restart local and remote NSMgrs:
```bash
kubectl delete pod ${NSMGR1} -n nsm-system
```
```bash
kubectl delete pod ${NSMGR2} -n nsm-system 
```

Waiting for new ones:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsmgr --field-selector spec.nodeName==${NSC_NODE} -n nsm-system
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsmgr --field-selector spec.nodeName==${NSE_NODE} -n nsm-system
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-local-nsmgr-remote-nsmgr -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-local-nsmgr-remote-nsmgr -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-local-nsmgr-remote-nsmgr
```
