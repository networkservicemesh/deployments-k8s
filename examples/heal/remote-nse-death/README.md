# Local NSE death

This example shows that NSM keeps working after the remote NSE death.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-remote-nse-death
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/remote-nse-death/nse-before-death?ref=dc452d06823a595372b4d70dd16337d5c87905cc
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel -n ns-remote-nse-death
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-remote-nse-death
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-kernel -n ns-remote-nse-death --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-remote-nse-death --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-remote-nse-death -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-remote-nse-death -- ping -c 4 172.16.1.101
```

Apply patch:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/remote-nse-death/nse-after-death?ref=dc452d06823a595372b4d70dd16337d5c87905cc
```

Wait for new NSE to start:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -l version=new -n ns-remote-nse-death
```

Find new NSE pod:
```bash
NEW_NSE=$(kubectl get pods -l app=nse-kernel -l version=new -n ns-remote-nse-death --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to new NSE:
```bash
kubectl exec ${NSC} -n ns-remote-nse-death -- ping -c 4 172.16.1.102
```

Ping from new NSE to NSC:
```bash
kubectl exec ${NEW_NSE} -n ns-remote-nse-death -- ping -c 4 172.16.1.103
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-remote-nse-death
```
