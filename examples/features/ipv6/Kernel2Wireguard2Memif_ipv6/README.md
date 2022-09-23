# Test kernel to wireguard to memif

This example shows that NSC and NSE on the different nodes could find and work with each other using IPv6.

NSC is using the `kernel` mechanism to connect to its local forwarder.
NSE is using the `memif` mechanism to connect to its local forwarder.
Forwarders are using the `wireguard` mechanism to connect with each other.

## Run

Create test namespace:
```bash
kubectl create ns ns-kernel2wireguard2memif-ipv6
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/ipv6/Kernel2Wireguard2Memif_ipv6?ref=7a0c00a9bee5af5efe8023031c816c29f50bcb02
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-kernel2wireguard2memif-ipv6
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-memif -n ns-kernel2wireguard2memif-ipv6
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=alpine -n ns-kernel2wireguard2memif-ipv6 --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-memif -n ns-kernel2wireguard2memif-ipv6 --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-kernel2wireguard2memif-ipv6 -- ping -c 4 2001:db8::
```

Ping from NSE to NSC:
```bash
result=$(kubectl exec "${NSE}" -n "ns-kernel2wireguard2memif-ipv6" -- vppctl ping 2001:db8::1 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-kernel2wireguard2memif-ipv6
```
