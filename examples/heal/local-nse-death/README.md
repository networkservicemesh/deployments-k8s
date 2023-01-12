# Local NSE death

This example shows that NSM keeps working after the local NSE death.

NSC and NSE are using the `kernel` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k nse-before-death
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-local-nse-death
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-local-nse-death
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=alpine -n ns-local-nse-death --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-local-nse-death --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-local-nse-death -- ping -c 4 172.16.1.100 -I 172.16.1.101
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-local-nse-death -- ping -c 4 172.16.1.101 -I 172.16.1.100
```

Stop NSE pod:
```bash
kubectl scale deployment nse-kernel -n ns-local-nse-death --replicas=0
```

```bash
kubectl exec ${NSC} -n ns-local-nse-death -- ping -c 4 172.16.1.100 -I 172.16.1.101 2>&1 | egrep "100% packet loss|Network unreachable|can't set multicast source"
```

Apply patch:
```bash
kubectl apply -k nse-after-death
```

Restore NSE pod:

```bash
kubectl scale deployment nse-kernel -n ns-local-nse-death --replicas=1
```

Wait for new NSE to start:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -l version=new -n ns-local-nse-death
```

Find new NSE pod:
```bash
NEW_NSE=$(kubectl get pods -l app=nse-kernel -l version=new -n ns-local-nse-death --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping should pass with newly configured addresses.

Ping from NSC to new NSE:
```bash
kubectl exec ${NSC} -n ns-local-nse-death -- ping -c 4 172.16.1.102 -I 172.16.1.103
```

Ping from new NSE to NSC:
```bash
kubectl exec ${NEW_NSE} -n ns-local-nse-death -- ping -c 4 172.16.1.103 -I 172.16.1.102
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-local-nse-death
```
