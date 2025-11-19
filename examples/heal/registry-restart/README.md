# Test registry restart

This example shows that NSM keeps working after the Registry restart.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/registry-restart/registry-before-death?ref=93c983419993c2d70b1b1029af77ce1596d4eb2f
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nettools -n ns-registry-restart
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=client-cp -n ns-registry-restart
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-registry-restart
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel-ipv6 -n ns-registry-restart
```

Find nsc and nse pods by labels:
```bash
NSC=$(kubectl get pods -l app=nettools -n ns-registry-restart --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-registry-restart --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec pods/nettools -n ns-registry-restart -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-registry-restart -- ping -c 4 172.16.1.101
```

Get link IDs of NSM interfaces in NSCs:

```bash
kubectl exec -n ns-registry-restart pod/client-cp -c nsc -- ip link show dev nsm-2
NSM_LINK_ID=$(kubectl exec -n ns-registry-restart pod/client-cp -c nsc -- ip link show dev nsm-2 | head -1| cut -f1 -d:)
kubectl exec -n ns-registry-restart pod/nettools -c nettools -- ip link show dev nsm-1
NSM_LID=$(kubectl exec -n ns-registry-restart pod/nettools -c nettools -- ip link show dev nsm-1 | head -1| cut -f1 -d:)
```

Find Registry:
```bash
REGISTRY=$(kubectl get pods -l app=registry -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Restart Registry and wait for it to start:
```bash
kubectl delete pod ${REGISTRY} -n nsm-system
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=registry -n nsm-system
```

Apply a new client:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/registry-restart/registry-after-death?ref=93c983419993c2d70b1b1029af77ce1596d4eb2f
```

Wait for a new NSC to start:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nettools-new -n ns-registry-restart
```

Ping from new NSC to NSE:
```bash
kubectl exec pods/nettools-new -n ns-registry-restart -- ping -c 4 172.16.1.102
```

Ping from NSE to new NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-registry-restart -- ping -c 4 172.16.1.103
```

The interface ID should be the same after registry restart:

```bash
sleep 120
kubectl exec -n ns-registry-restart pod/client-cp -c nsc -- ip link show dev nsm-2
CHECK_NSM_LINK_ID=$(kubectl exec -n ns-registry-restart pod/client-cp -c nsc -- ip link show dev nsm-2 | head -1| cut -f1 -d:)
kubectl exec -n ns-registry-restart pod/nettools -c nettools -- ip link show dev nsm-1
CHECK_NSM_LID=$(kubectl exec -n ns-registry-restart pod/nettools -c nettools -- ip link show dev nsm-1 | head -1| cut -f1 -d:)
test "$CHECK_NSM_LID" == "$NSM_LID" && test "$CHECK_NSM_LINK_ID" == "$NSM_LINK_ID"
```

Check policy based routing:
```bash
result=$(kubectl exec pods/nettools -n ns-registry-restart  -c nettools -- ip r get 172.16.3.1 from 172.16.2.201 ipproto tcp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.3.1 from 172.16.2.201 via 172.16.2.200 dev nsm-1 table 1"
```

```bash
result=$(kubectl exec pods/nettools -n ns-registry-restart  -c nettools -- ip r get 172.16.3.1 from 172.16.2.201 ipproto tcp sport 5555)
echo ${result}
echo ${result} | grep -E -q "172.16.3.1 from 172.16.2.201 dev nsm-1 table 2"
```

```bash
result=$(kubectl exec pods/nettools -n ns-registry-restart  -c nettools -- ip r get 172.16.4.1 ipproto udp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.4.1 dev nsm-1 table 3 src 172.16.1.101"
```

```bash
result=$(kubectl exec pods/nettools -n ns-registry-restart  -c nettools -- ip r get 172.16.4.1 ipproto udp dport 6668)
echo ${result}
echo ${result} | grep -E -q "172.16.4.1 dev nsm-1 table 4 src 172.16.1.101"
```

```bash
result=$(kubectl exec pods/nettools -n ns-registry-restart  -c nettools -- ip -6 route get 2004::5 from 2004::3 ipproto udp dport 5555)
echo ${result}
echo ${result} | grep -E -q "via 2004::6 dev nsm-1 table 5 src 2004::3"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-registry-restart
```
