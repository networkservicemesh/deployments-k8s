# Dataplane Interruption

This example shows that NSM not only checks that control plane is fine (NSMgr, Registry, etc), but also catches that data plane is interrupted and performs healing when it's restored.

NSC and NSE are using the `kernel` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-dataplane-interrupt
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/dataplane-interrupt?ref=c3fee860be1688b5e3e5450ccca9fc9770ae963c
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel -n ns-dataplane-interrupt
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-dataplane-interrupt
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-kernel -n ns-dataplane-interrupt --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-dataplane-interrupt --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-dataplane-interrupt -c nsc -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-dataplane-interrupt -- ping -c 4 172.16.1.101
```

Run a pinger process in the background. The pinger will run until it encounters missing packets.
```bash
PINGER_PATH=/tmp/done-${RANDOM}
kubectl exec ${NSC} -n ns-dataplane-interrupt -c nsc -- sh -c '
  PINGER_PATH=$1; rm -f "$PINGER_PATH"
  seq=0
  ping -i 0.2 172.16.1.100 | while :; do
    read -t 1 line || { echo ping timeout; touch $PINGER_PATH; break; }
    seq1=$(echo $line | sed -n "s/.* seq=\([0-9]\+\) .*/\1/p")
    [ "$seq1" ] || continue
    [ "$seq" -eq "$seq1" ] || { echo missing $((seq1 - seq)) pings; touch $PINGER_PATH; break; }
    seq=$((seq1+1))
  done
' - "$PINGER_PATH" &
sleep 5
kubectl exec ${NSC} -n ns-dataplane-interrupt -c nsc -- test ! -f /tmp/done || { echo pinger is done; false; }
```

Simulate data plane interruption by shutting down the kernel interface:
```bash
kubectl exec ${NSC} -n ns-dataplane-interrupt -c alpine -- ip link set nsm-1 down
```

Wait until the pinger process stops. This would be an indication that the data plane was temporarily interrupted.
```bash
kubectl exec ${NSC} -n ns-dataplane-interrupt -c nsc -- sh -c 'timeout 10 sh -c "while ! [ -f \"$1\" ];do sleep 1; done"' - "$PINGER_PATH"
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-dataplane-interrupt -c nsc -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-dataplane-interrupt -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-dataplane-interrupt
```
