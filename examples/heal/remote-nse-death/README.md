# Remote NSE death

This example shows that NSM keeps working after the remote NSE death.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/remote-nse-death/nse-before-death?ref=00c337b4121053dffae012116d8b939066ba2bd3
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nettools -n ns-remote-nse-death
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-remote-nse-death
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=nettools -n ns-remote-nse-death --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-remote-nse-death --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec pods/nettools -n ns-remote-nse-death -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-remote-nse-death -- ping -c 4 172.16.1.101
```

Apply patch. It recreates NSE with a new label:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/remote-nse-death/nse-after-death?ref=00c337b4121053dffae012116d8b939066ba2bd3
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
kubectl exec pods/nettools -n ns-remote-nse-death -- ping -c 4 172.16.1.102
```

Ping from new NSE to NSC:
```bash
kubectl exec ${NEW_NSE} -n ns-remote-nse-death -- ping -c 4 172.16.1.103
```

Check policy based routing:
```bash
result=$(kubectl exec pods/nettools -n ns-remote-nse-death  -c nettools -- ip r get 172.16.3.1 from 172.16.2.201 ipproto tcp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.3.1 from 172.16.2.201 via 172.16.2.200 dev nsm-1 table 1"
```

```bash
result=$(kubectl exec pods/nettools -n ns-remote-nse-death  -c nettools -- ip r get 172.16.3.1 from 172.16.2.201 ipproto tcp sport 5555)
echo ${result}
echo ${result} | grep -E -q "172.16.3.1 from 172.16.2.201 dev nsm-1 table 2"
```

```bash
result=$(kubectl exec pods/nettools -n ns-remote-nse-death  -c nettools -- ip r get 172.16.4.1 ipproto udp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.4.1 dev nsm-1 table 3 src 172.16.1.101"
```

```bash
result=$(kubectl exec pods/nettools -n ns-remote-nse-death  -c nettools -- ip r get 172.16.4.1 ipproto udp dport 6668)
echo ${result}
echo ${result} | grep -E -q "172.16.4.1 dev nsm-1 table 4 src 172.16.1.101"
```

```bash
result=$(kubectl exec pods/nettools -n ns-remote-nse-death  -c nettools -- ip -6 route get 2004::5 from 2004::3 ipproto udp dport 5555)
echo ${result}
echo ${result} | grep -E -q "via 2004::6 dev nsm-1 table 5 src 2004::3"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-remote-nse-death
```
