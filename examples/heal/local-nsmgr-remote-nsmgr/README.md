# Local NSMgr + Remote NSMgr restart

This example shows that NSM keeps working after the local NSMgr + remote NSMgr restart.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/local-nsmgr-remote-nsmgr?ref=b942b273456a2d1fcbacd3abe75d2138e91fb2a2
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-local-nsmgr-remote-nsmgr
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-local-nsmgr-remote-nsmgr
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-local-nsmgr-remote-nsmgr -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-local-nsmgr-remote-nsmgr -- ping -c 4 172.16.1.101
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
kubectl exec pods/alpine -n ns-local-nsmgr-remote-nsmgr -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-local-nsmgr-remote-nsmgr -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-local-nsmgr-remote-nsmgr
```
