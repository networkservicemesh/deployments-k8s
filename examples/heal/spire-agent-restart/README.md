# SPIRE agents restart

This example shows that NSM keeps working after the SPIRE agents restarted.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-spire-agent-restart
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/spire-agent-restart?ref=b1e35499cffc55578653994f1e554ed558b69d8e
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-spire-agent-restart
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-spire-agent-restart
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-spire-agent-restart -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-spire-agent-restart -- ping -c 4 172.16.1.101
```

Find SPIRE Agents:
```bash
AGENTS=$(kubectl get pods -l app=spire-agent -n spire --template '{{range .items}}{{.metadata.name}}{{" "}}{{end}}')
```

Restart SPIRE agents and wait for them to start:
```bash
kubectl delete pod $AGENTS -n spire
```

```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=spire-agent -n spire
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-spire-agent-restart -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-spire-agent-restart -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-spire-agent-restart
```
