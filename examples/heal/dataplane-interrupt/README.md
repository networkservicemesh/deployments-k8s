# Dataplane Interruption

This example shows that NSM not only checks that control plane is fine (NSMgr, Registry, etc), but also catches that data plane is interrupted and performs healing when it's restored.

NSC and NSE are using the `kernel` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/dataplane-interrupt?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nettools -n ns-dataplane-interrupt
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-dataplane-interrupt
```

Ping from NSC to NSE:
```bash
kubectl exec pods/nettools -n ns-dataplane-interrupt -c nettools -- ping -c 4 -I 172.16.1.101 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-dataplane-interrupt -- ping -c 4 172.16.1.101 -I 172.16.1.100
```

Run a pinger process in the background. The pinger will run until it encounters missing packets.
```bash
PINGER_PATH=/tmp/done-${RANDOM}
kubectl exec pods/nettools -n ns-dataplane-interrupt -c nettools -- sh -c '
  PINGER_PATH=$1; rm -f "$PINGER_PATH"
  seq=0
  ping -i 0.2 -I 172.16.1.101 172.16.1.100 | while :; do
    read -t 1 line || { echo ping timeout; touch $PINGER_PATH; break; }
    seq1=$(echo $line | sed -n "s/.* seq=\([0-9]\+\) .*/\1/p")
    [ "$seq1" ] || continue
    [ "$seq" -eq "$seq1" ] || { echo missing $((seq1 - seq)) pings; touch $PINGER_PATH; break; }
    seq=$((seq1+1))
  done
' - "$PINGER_PATH" &
sleep 5
kubectl exec pods/nettools -n ns-dataplane-interrupt -- test ! -f /tmp/done || { echo pinger is done; false; }
```

Simulate data plane interruption by shutting down the kernel interface:
```bash
kubectl exec pods/nettools -n ns-dataplane-interrupt  -c nettools -- ip link set nsm-1 down
```

Wait until the pinger process stops. This would be an indication that the data plane was temporarily interrupted.
```bash
kubectl exec pods/nettools -n ns-dataplane-interrupt -- sh -c 'timeout 10 sh -c "while ! [ -f \"$1\" ];do sleep 1; done"' - "$PINGER_PATH"
```

Ping from NSC to NSE:
```bash
kubectl exec pods/nettools -n ns-dataplane-interrupt -c nettools -- ping -c 4 -I 172.16.1.101 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-dataplane-interrupt -- ping -c 4 172.16.1.101 -I 172.16.1.100
```

Check policy based routing:
```bash
result=$(kubectl exec pods/nettools -n ns-dataplane-interrupt  -c nettools -- ip r get 172.16.3.1 from 172.16.2.201 ipproto tcp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.3.1 from 172.16.2.201 via 172.16.2.200 dev nsm-1 table 1"
```

```bash
result=$(kubectl exec pods/nettools -n ns-dataplane-interrupt  -c nettools -- ip r get 172.16.3.1 from 172.16.2.201 ipproto tcp sport 5555)
echo ${result}
echo ${result} | grep -E -q "172.16.3.1 from 172.16.2.201 dev nsm-1 table 2"
```

```bash
result=$(kubectl exec pods/nettools -n ns-dataplane-interrupt  -c nettools -- ip r get 172.16.4.1 ipproto udp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.4.1 dev nsm-1 table 3 src 172.16.1.101"
```

```bash
result=$(kubectl exec pods/nettools -n ns-dataplane-interrupt  -c nettools -- ip r get 172.16.4.1 ipproto udp dport 6668)
echo ${result}
echo ${result} | grep -E -q "172.16.4.1 dev nsm-1 table 4 src 172.16.1.101"
```

```bash
result=$(kubectl exec pods/nettools -n ns-dataplane-interrupt  -c nettools -- ip -6 route get 2004::5 from 2004::3 ipproto udp dport 5555)
echo ${result}
echo ${result} | grep -E -q "via 2004::6 dev nsm-1 table 5 src 2004::3"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-dataplane-interrupt
```
