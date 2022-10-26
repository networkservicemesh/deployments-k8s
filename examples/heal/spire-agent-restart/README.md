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
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel -n ns-spire-agent-restart
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-spire-agent-restart
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-kernel -n ns-spire-agent-restart --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-spire-agent-restart --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-spire-agent-restart -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-spire-agent-restart -- ping -c 4 172.16.1.101
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
kubectl exec ${NSC} -n ns-spire-agent-restart -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-spire-agent-restart -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-spire-agent-restart
```
