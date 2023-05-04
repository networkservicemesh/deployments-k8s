# Policy Based Routing

This example shows policy based routing usage.

NSE is configured by ConfigMap that contains the policy routes.

Based on Kernel2Kernel example.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/policy-based-routing?ref=1bad0a040fa2d6f38bb05ec0035cb382ce15b497
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nettools -n ns-policy-based-routing
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-policy-based-routing
```

Ping from NSC to NSE:
```bash
kubectl exec pods/nettools -n ns-policy-based-routing -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-policy-based-routing -- ping -c 4 172.16.1.101
```

Check policy based routing:
```bash
result=$(kubectl exec pods/nettools -n ns-policy-based-routing -- ip r get 172.16.3.1 from 172.16.2.201 ipproto tcp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.3.1 from 172.16.2.201 via 172.16.2.200 dev nsm-1 table 1"
```

```bash
result=$(kubectl exec pods/nettools -n ns-policy-based-routing -- ip r get 172.16.3.1 from 172.16.2.201 ipproto tcp sport 5555)
echo ${result}
echo ${result} | grep -E -q "172.16.3.1 from 172.16.2.201 dev nsm-1 table 2"
```

```bash
result=$(kubectl exec pods/nettools -n ns-policy-based-routing -- ip r get 172.16.4.1 ipproto udp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.4.1 dev nsm-1 table 3 src 172.16.1.101"
```

```bash
result=$(kubectl exec pods/nettools -n ns-policy-based-routing -- ip r get 172.16.4.1 ipproto udp dport 6668)
echo ${result}
echo ${result} | grep -E -q "172.16.4.1 dev nsm-1 table 4 src 172.16.1.101"
```

```bash
result=$(kubectl exec pods/nettools -n ns-policy-based-routing -- ip -6 route get 2004::5 from 2004::3 ipproto udp dport 5555)
echo ${result}
echo ${result} | grep -E -q "via 2004::6 dev nsm-1 table 5 src 2004::3"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-policy-based-routing
```
