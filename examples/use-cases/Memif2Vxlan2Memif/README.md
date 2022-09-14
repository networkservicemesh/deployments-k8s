# Test memif to vxlan to memif connection

This example shows that NSC and NSE on the different nodes could find and work with each other.

NSC and NSE are using the `memif` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-memif2vxlan2memif
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/Memif2Vxlan2Memif?ref=ac45dd7fdab77190c61a128c3b7dcb1a4b46b335
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-memif -n ns-memif2vxlan2memif
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-memif -n ns-memif2vxlan2memif
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-memif -n ns-memif2vxlan2memif --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-memif -n ns-memif2vxlan2memif --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
result=$(kubectl exec "${NSC}" -n "ns-memif2vxlan2memif" -- vppctl ping 172.16.1.100 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

Ping from NSE to NSC:
```bash
result=$(kubectl exec "${NSE}" -n "ns-memif2vxlan2memif" -- vppctl ping 172.16.1.101 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-memif2vxlan2memif
```
