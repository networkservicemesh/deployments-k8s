# SPIRE server restart

This example shows that NSM keeps working after SPIRE server restarted.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-spire-server-restart
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/spire-server-restart?ref=v1.14.5-rc.3
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nettools -n ns-spire-server-restart
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-spire-server-restart
```

Ping from NSC to NSE:
```bash
kubectl exec pods/nettools -n ns-spire-server-restart -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-spire-server-restart -- ping -c 4 172.16.1.101
```

Restart SPIRE server and wait for it to start:
```bash
kubectl delete pod spire-server-0 -n spire
```
```bash
kubectl wait --for=condition=ready --timeout=3m pod -l app=spire-server -n spire
```

Ping from NSC to NSE:
```bash
kubectl exec pods/nettools -n ns-spire-server-restart -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-spire-server-restart -- ping -c 4 172.16.1.101
```

Check policy based routing:
```bash
result=$(kubectl exec pods/nettools -n ns-spire-server-restart  -c nettools -- ip r get 172.16.3.1 from 172.16.2.201 ipproto tcp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.3.1 from 172.16.2.201 via 172.16.2.200 dev nsm-1 table 1"
```

```bash
result=$(kubectl exec pods/nettools -n ns-spire-server-restart  -c nettools -- ip r get 172.16.3.1 from 172.16.2.201 ipproto tcp sport 5555)
echo ${result}
echo ${result} | grep -E -q "172.16.3.1 from 172.16.2.201 dev nsm-1 table 2"
```

```bash
result=$(kubectl exec pods/nettools -n ns-spire-server-restart  -c nettools -- ip r get 172.16.4.1 ipproto udp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.4.1 dev nsm-1 table 3 src 172.16.1.101"
```

```bash
result=$(kubectl exec pods/nettools -n ns-spire-server-restart  -c nettools -- ip r get 172.16.4.1 ipproto udp dport 6668)
echo ${result}
echo ${result} | grep -E -q "172.16.4.1 dev nsm-1 table 4 src 172.16.1.101"
```

```bash
result=$(kubectl exec pods/nettools -n ns-spire-server-restart  -c nettools -- ip -6 route get 2004::5 from 2004::3 ipproto udp dport 5555)
echo ${result}
echo ${result} | grep -E -q "via 2004::6 dev nsm-1 table 5 src 2004::3"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-spire-server-restart
```
