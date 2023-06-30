# Remote NSMgr death

This example shows that NSM keeps working after the remote NSMgr death.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/remote-nsmgr-death/remote-nse?ref=ff9e7d8023a75935f9a31eb2b1f30ed482ab63ea
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-remote-nsmgr-death
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-remote-nsmgr-death
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-remote-nsmgr-death -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-remote-nsmgr-death -- ping -c 4 172.16.1.101
```

Kill remote NSMgr:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/remote-nsmgr-death/nsmgr-death?ref=ff9e7d8023a75935f9a31eb2b1f30ed482ab63ea
```

Start local NSE instead of the remote one:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/remote-nsmgr-death/local-nse?ref=ff9e7d8023a75935f9a31eb2b1f30ed482ab63ea
```

Wait for the new NSE to start:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l nse-version=local -n ns-remote-nsmgr-death
```

Find new NSE pod:
```bash
NEW_NSE=$(kubectl get pods -l nse-version=local -n ns-remote-nsmgr-death --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to new NSE:
```bash
kubectl exec pods/alpine -n ns-remote-nsmgr-death -- ping -c 4 172.16.1.102
```

Ping from new NSE to NSC:
```bash
kubectl exec ${NEW_NSE} -n ns-remote-nsmgr-death -- ping -c 4 172.16.1.103
```

## Cleanup

Restore NSMgr setup:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/apps/nsmgr?ref=ff9e7d8023a75935f9a31eb2b1f30ed482ab63ea -n nsm-system
```

Delete ns:
```bash
kubectl delete ns ns-remote-nsmgr-death
```
