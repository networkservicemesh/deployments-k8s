# Test remote Forwarder death

This example shows that NSM keeps working after the remote Forwarder death.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/remote-forwarder-death-ip?ref=c340ebd0c2ba2d43a9b162268a3606d017cd31e9
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-remote-forwarder-death-ip
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-remote-forwarder-death-ip
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-remote-forwarder-death-ip -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-remote-forwarder-death-ip -- ping -c 4 172.16.1.101
```

Find nse node:
```bash
NSE_NODE=$(kubectl get pods -l app=nse-kernel -n ns-remote-forwarder-death-ip --template '{{range .items}}{{.spec.nodeName}}{{"\n"}}{{end}}')
```

Find remote Forwarder:
```bash
FORWARDER=$(kubectl get pods -l app=forwarder-vpp --field-selector spec.nodeName==${NSE_NODE} -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Remove remote Forwarder and wait for a new one to start:
```bash
kubectl delete pod -n nsm-system ${FORWARDER}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=forwarder-vpp --field-selector spec.nodeName==${NSE_NODE} -n nsm-system
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-remote-forwarder-death-ip -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-remote-forwarder-death-ip -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-remote-forwarder-death-ip
```
