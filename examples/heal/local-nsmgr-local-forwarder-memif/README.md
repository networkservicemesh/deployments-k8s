# Local NSMgr + Local Forwarder restart

This example shows that NSM keeps working after the local NSMgr + local Forwarder restart.

NSC and NSE are using the `memif` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-local-nsmgr-local-forwarder-memif
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/local-nsmgr-local-forwarder-memif?ref=ba19e09c05e4bc2b77496de6082ddd5014d33413
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-memif -n ns-local-nsmgr-local-forwarder-memif
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-memif -n ns-local-nsmgr-local-forwarder-memif
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-memif -n ns-local-nsmgr-local-forwarder-memif --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-memif -n ns-local-nsmgr-local-forwarder-memif --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
result=$(kubectl exec "${NSC}" -n "ns-local-nsmgr-local-forwarder-memif" -- vppctl ping 172.16.1.100 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

Ping from NSE to NSC:
```bash
result=$(kubectl exec "${NSE}" -n "ns-local-nsmgr-local-forwarder-memif" -- vppctl ping 172.16.1.101 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

Find nsc node:
```bash
NSC_NODE=$(kubectl get pods -l app=nsc-memif -n ns-local-nsmgr-local-forwarder-memif --template '{{range .items}}{{.spec.nodeName}}{{"\n"}}{{end}}')
```

Find local NSMgr pod:
```bash
NSMGR=$(kubectl get pods -l app=nsmgr --field-selector spec.nodeName==${NSC_NODE} -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Find local Forwarder:
```bash
FORWARDER=$(kubectl get pods -l app=forwarder-vpp --field-selector spec.nodeName==${NSC_NODE} -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Restart local NSMgr and Forwarder:
```bash
kubectl delete pod ${NSMGR} -n nsm-system
```
```bash
kubectl delete pod ${FORWARDER} -n nsm-system 
```

Waiting for new ones:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsmgr --field-selector spec.nodeName==${NSC_NODE} -n nsm-system
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=forwarder-vpp --field-selector spec.nodeName==${NSC_NODE} -n nsm-system
```

Ping from NSC to NSE:
```bash
result=$(kubectl exec "${NSC}" -n "ns-local-nsmgr-local-forwarder-memif" -- vppctl ping 172.16.1.100 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

Ping from NSE to NSC:
```bash
result=$(kubectl exec "${NSE}" -n "ns-local-nsmgr-local-forwarder-memif" -- vppctl ping 172.16.1.101 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-local-nsmgr-local-forwarder-memif
```
