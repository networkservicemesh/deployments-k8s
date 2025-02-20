# Local NSMgr restart

This example shows that NSM keeps working after the local NSMgr restart.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/local-nsmgr-restart?ref=a98f08d26c1354b0b6cc1835c2f5f4bb5c4e33e3
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-local-nsmgr-restart
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-local-nsmgr-restart
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-local-nsmgr-restart -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-local-nsmgr-restart -- ping -c 4 172.16.1.101
```

Find nsc node:
```bash
NSC_NODE=$(kubectl get pods -l app=alpine -n ns-local-nsmgr-restart --template '{{range .items}}{{.spec.nodeName}}{{"\n"}}{{end}}')
```

Find local NSMgr pod:
```bash
NSMGR=$(kubectl get pods -l app=nsmgr --field-selector spec.nodeName==${NSC_NODE} -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Restart local NSMgr and wait for it to start:
```bash
kubectl delete pod ${NSMGR} -n nsm-system
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsmgr --field-selector spec.nodeName==${NSC_NODE} -n nsm-system
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-local-nsmgr-restart -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-local-nsmgr-restart -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-local-nsmgr-restart
```
