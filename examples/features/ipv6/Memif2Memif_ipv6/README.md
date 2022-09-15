# Test memif to memif connection

This example shows that NSC and NSE on the one node can find each other by ipv6 addresses.

NSC and NSE are using the `memif` mechanism to connect to its local forwarder.

## Run

Create test namespace:
```bash
kubectl create ns ns-memif2memif-ipv6
```

Deploy NSC and NSE:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-memif -n ns-memif2memif-ipv6
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-memif -n ns-memif2memif-ipv6
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-memif -n ns-memif2memif-ipv6 --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-memif -n ns-memif2memif-ipv6 --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Check connectivity:
```bash
result=$(kubectl exec "${NSC}" -n "ns-memif2memif-ipv6" -- vppctl ping ipv6 2001:db8:: repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

Check connectivity:
```bash
result=$(kubectl exec "${NSE}" -n "ns-memif2memif-ipv6" -- vppctl ping ipv6 2001:db8::1 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-memif2memif-ipv6
```
