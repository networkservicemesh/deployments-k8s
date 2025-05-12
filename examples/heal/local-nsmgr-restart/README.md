# Local NSMgr restart

This example shows that NSM keeps working after the local NSMgr restart.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/local-nsmgr-restart?ref=v1.14.5
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nettools -n ns-local-nsmgr-restart
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-local-nsmgr-restart
```

Ping from NSC to NSE:
```bash
kubectl exec pods/nettools -n ns-local-nsmgr-restart -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-local-nsmgr-restart -- ping -c 4 172.16.1.101
```

Find nsc node:
```bash
NSC_NODE=$(kubectl get pods -l app=nettools -n ns-local-nsmgr-restart --template '{{range .items}}{{.spec.nodeName}}{{"\n"}}{{end}}')
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
kubectl exec pods/nettools -n ns-local-nsmgr-restart -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-local-nsmgr-restart -- ping -c 4 172.16.1.101
```

Check policy based routing:
```bash
result=$(kubectl exec pods/nettools -n ns-local-nsmgr-restart  -c nettools -- ip r get 172.16.3.1 from 172.16.2.201 ipproto tcp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.3.1 from 172.16.2.201 via 172.16.2.200 dev nsm-1 table 1"
```

```bash
result=$(kubectl exec pods/nettools -n ns-local-nsmgr-restart  -c nettools -- ip r get 172.16.3.1 from 172.16.2.201 ipproto tcp sport 5555)
echo ${result}
echo ${result} | grep -E -q "172.16.3.1 from 172.16.2.201 dev nsm-1 table 2"
```

```bash
result=$(kubectl exec pods/nettools -n ns-local-nsmgr-restart  -c nettools -- ip r get 172.16.4.1 ipproto udp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.4.1 dev nsm-1 table 3 src 172.16.1.101"
```

```bash
result=$(kubectl exec pods/nettools -n ns-local-nsmgr-restart  -c nettools -- ip r get 172.16.4.1 ipproto udp dport 6668)
echo ${result}
echo ${result} | grep -E -q "172.16.4.1 dev nsm-1 table 4 src 172.16.1.101"
```

```bash
result=$(kubectl exec pods/nettools -n ns-local-nsmgr-restart  -c nettools -- ip -6 route get 2004::5 from 2004::3 ipproto udp dport 5555)
echo ${result}
echo ${result} | grep -E -q "via 2004::6 dev nsm-1 table 5 src 2004::3"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-local-nsmgr-restart
```
