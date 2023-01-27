# Test kernel to kernel connection over VLAN Trunking at NSE side


This example shows that NS Clients and NSE on the one node can find each other. 

NS Clients and NSE are using the `kernel` mechanism to connect to its local ovs forwarder.
The NS Client connections are multiplexed over single veth pair interface on the NSE side.

## Requires

Make sure that you have completed steps from [ovs](../../ovs) setup.
There is more consumption of heap memory by NSE pod due to vpp process when host is configured with
hugepage, so in this case NSE pod should be created with memory limit > 2.2 GB.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/Kernel2KernelVLAN?ref=54966bc49b9bcaf6a6c1bcd80a1619440bc4f9db
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel -n ns-kernel2kernel-vlan
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-kernel2kernel-vlan
```

Choose one ns client pod and nse pod by labels:
```bash
NSC=$((kubectl get pods -l app=nsc-kernel -n ns-kernel2kernel-vlan --template '{{range .items}}{{.metadata.name}}{{" "}}{{end}}') | cut -d' ' -f1)
TARGET_IP=$(kubectl exec -ti ${NSC} -n ns-kernel2kernel-vlan -- ip route show | grep 172.16 | cut -d' ' -f1)
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-kernel2kernel-vlan --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-kernel2kernel-vlan -- ping -c 4 ${TARGET_IP}
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-kernel2kernel-vlan
```
