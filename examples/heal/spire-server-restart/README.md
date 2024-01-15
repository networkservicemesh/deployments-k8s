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
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/spire-server-restart?ref=d186ae9a814b58cedc59b25bead7ac2daaa4ab28
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-spire-server-restart
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-spire-server-restart
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-spire-server-restart -- ping -c 4 172.16.1.100
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
kubectl exec pods/alpine -n ns-spire-server-restart -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-spire-server-restart -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-spire-server-restart
```
