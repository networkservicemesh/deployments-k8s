# Remote NSMgr restart

This example shows that NSM keeps working after the remote NSMgr restart.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/remote-nsmgr-restart?ref=eee3a3096a6802b6280dc4b4a027cf795328c526
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-remote-nsmgr-restart
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-remote-nsmgr-restart
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=alpine -n ns-remote-nsmgr-restart --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-remote-nsmgr-restart --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-remote-nsmgr-restart -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-remote-nsmgr-restart -- ping -c 4 172.16.1.101
```

Find nse node:
```bash
NSE_NODE=$(kubectl get pods -l app=nse-kernel -n ns-remote-nsmgr-restart --template '{{range .items}}{{.spec.nodeName}}{{"\n"}}{{end}}')
```

Find remote NSMgr pod:
```bash
NSMGR=$(kubectl get pods -l app=nsmgr --field-selector spec.nodeName==${NSE_NODE} -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Restart remote NSMgr and wait for it to start:
```bash
kubectl delete pod ${NSMGR} -n nsm-system
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsmgr --field-selector spec.nodeName==${NSE_NODE} -n nsm-system
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-remote-nsmgr-restart -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-remote-nsmgr-restart -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-remote-nsmgr-restart
```
