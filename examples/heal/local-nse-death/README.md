# Local NSE death

This example shows that NSM keeps working after the local NSE death.

NSC and NSE are using the `kernel` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/local-nse-death/nse-before-death?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nettools -n ns-local-nse-death
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-local-nse-death
```

Ping from NSC to NSE:
```bash
kubectl exec pods/nettools -n ns-local-nse-death -c nettools -- ping -c 4 -I 172.16.1.101 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-local-nse-death -- ping -c 4 172.16.1.101 -I 172.16.1.100
```

Stop NSE pod:
```bash
kubectl scale deployment nse-kernel -n ns-local-nse-death --replicas=0
```

```bash
kubectl exec pods/nettools -n ns-local-nse-death -c nettools -- ping -c 4 -I 172.16.1.101 172.16.1.100 2>&1 | egrep "Address not available|100% packet loss|Network unreachable|can't set multicast source"
```

Apply patch:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/local-nse-death/nse-after-death?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
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
kubectl exec pods/nettools -n ns-local-nse-death -c nettools -- ping -c 4 -I 172.16.1.103 172.16.1.102
```

Ping from new NSE to NSC:
```bash
kubectl exec ${NEW_NSE} -n ns-local-nse-death -- ping -c 4 172.16.1.103 -I 172.16.1.102
```

Check policy based routing:
```bash
result=$(kubectl exec pods/nettools -n ns-local-nse-death -c nettools -- ip r get 172.16.3.1 from 172.16.2.201 ipproto tcp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.3.1 from 172.16.2.201 via 172.16.2.200 dev nsm-1 table 1"
```

```bash
result=$(kubectl exec pods/nettools -n ns-local-nse-death  -c nettools -- ip r get 172.16.3.1 from 172.16.2.201 ipproto tcp sport 5555)
echo ${result}
echo ${result} | grep -E -q "172.16.3.1 from 172.16.2.201 dev nsm-1 table 2"
```

```bash
result=$(kubectl exec pods/nettools -n ns-local-nse-death  -c nettools -- ip r get 172.16.4.1 ipproto udp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.4.1 dev nsm-1 table 3 src 172.16.1.101"
```

```bash
result=$(kubectl exec pods/nettools -n ns-local-nse-death  -c nettools -- ip r get 172.16.4.1 ipproto udp dport 6668)
echo ${result}
echo ${result} | grep -E -q "172.16.4.1 dev nsm-1 table 4 src 172.16.1.101"
```

```bash
result=$(kubectl exec pods/nettools -n ns-local-nse-death  -c nettools -- ip -6 route get 2004::5 from 2004::3 ipproto udp dport 5555)
echo ${result}
echo ${result} | grep -E -q "via 2004::6 dev nsm-1 table 5 src 2004::3"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-local-nse-death
```
