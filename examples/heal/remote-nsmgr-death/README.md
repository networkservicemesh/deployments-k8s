# Remote NSMgr death

This example shows that NSM keeps working after the remote NSMgr death.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-remote-nsmgr-death
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/remote-nsmgr-death/remote-nse?ref=821b2c7867ec0df8d197c92e2b4657101b90c357
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-remote-nsmgr-death
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-remote-nsmgr-death
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=alpine -n ns-remote-nsmgr-death --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-remote-nsmgr-death --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-remote-nsmgr-death -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-remote-nsmgr-death -- ping -c 4 172.16.1.101
```

Kill remote NSMgr:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/remote-nsmgr-death/nsmgr-death?ref=821b2c7867ec0df8d197c92e2b4657101b90c357
```

Start local NSE instead of the remote one:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/remote-nsmgr-death/local-nse?ref=821b2c7867ec0df8d197c92e2b4657101b90c357
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
kubectl exec ${NSC} -n ns-remote-nsmgr-death -- ping -c 4 172.16.1.102
```

Ping from new NSE to NSC:
```bash
kubectl exec ${NEW_NSE} -n ns-remote-nsmgr-death -- ping -c 4 172.16.1.103
```

## Cleanup

Restore NSMgr setup:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/apps/nsmgr?ref=821b2c7867ec0df8d197c92e2b4657101b90c357 -n nsm-system
```

Delete ns:
```bash
kubectl delete ns ns-remote-nsmgr-death
```
