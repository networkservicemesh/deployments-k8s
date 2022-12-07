# Test Smart VF connection

This example shows that NSC and NSE can work with each other over the SmartVF dual mode (kernel or dpdk) connection.

## Requires

Make sure that you have completed steps from [ovs](../../ovs) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-smartvf2smartvf
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/SmartVF2SmartVF?ref=eeb5262e895aa9f6b74aaa8f23cd4b7cd4e89533
```

Wait for applications ready:
```bash
kubectl -n ns-smartvf2smartvf wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel
```
```bash
kubectl -n ns-smartvf2smartvf wait --for=condition=ready --timeout=1m pod -l app=nse-kernel
```

Get NSC pod:
```bash
NSC=$(kubectl -n ns-smartvf2smartvf get pods -l app=nsc-kernel --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl -n ns-smartvf2smartvf exec ${NSC} -- ping -c 4 172.16.1.100
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-smartvf2smartvf
```
