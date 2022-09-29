# Test SR-IOV kernel connection

This example shows that NSC and NSE can work with each other over the SR-IOV kernel connection.

## Requires

Make sure that you have completed steps from [sriov](../../sriov) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-sriov-kernel2noop
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/SriovKernel2Noop?ref=507ad9cfd9b503727e55ae29b51f339a328f4da7
```

Wait for applications ready:
```bash
kubectl -n ns-sriov-kernel2noop wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel
```
```bash
kubectl -n ns-sriov-kernel2noop wait --for=condition=ready --timeout=1m pod -l app=nse-kernel
```
```bash
kubectl -n ns-sriov-kernel2noop wait --for=condition=ready --timeout=1m pod -l app=ponger
```

Get NSC pod:
```bash
NSC=$(kubectl -n ns-sriov-kernel2noop get pods -l app=nsc-kernel --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl -n ns-sriov-kernel2noop exec ${NSC} -- ping -c 4 172.16.1.100
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-sriov-kernel2noop
```
