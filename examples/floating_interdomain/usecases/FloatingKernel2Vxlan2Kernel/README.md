# Floating interdomain kernel2vxlan2kernel example

This example shows that NSC can reach NSE registered in floating registry.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

NSE is registering in the floating registry.


## Requires

Make sure that you have completed steps from [interdomain](../../)

## Run

**1. Deploy endpoint on cluster2**

```bash
export KUBECONFIG=$KUBECONFIG2
```

```bash
kubectl create ns ns-floating-kernel2vxlan2kernel-floating-interdomain-cluster-2
```

Deploy NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/floating_interdomain/usecases/FloatingKernel2Vxlan2Kernel/cluster2?ref=2b4374aec83267373830d4ad69e7b9a661b51810
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-floating-kernel2vxlan2kernel-floating-interdomain-cluster-2
```

Find NSE pod by labels:
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-floating-kernel2vxlan2kernel-floating-interdomain-cluster-2 --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
[[ ! -z $NSE ]]
```

**2. Deploy client on cluster1**

```bash
export KUBECONFIG=$KUBECONFIG1
```

```bash
kubectl create ns ns-floating-kernel2vxlan2kernel-floating-interdomain-cluster-1
```

Deploy NSC:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/floating_interdomain/usecases/FloatingKernel2Vxlan2Kernel/cluster1?ref=2b4374aec83267373830d4ad69e7b9a661b51810
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=nsc-kernel -n ns-floating-kernel2vxlan2kernel-floating-interdomain-cluster-1
```

Find NSC pod by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-kernel -n ns-floating-kernel2vxlan2kernel-floating-interdomain-cluster-1 --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
[[ ! -z $NSC ]]
```

**3. Check connectivity**

Switch to *cluster1*:

```bash
export KUBECONFIG=$KUBECONFIG1
```

```bash
kubectl exec ${NSC} -n ns-floating-kernel2vxlan2kernel-floating-interdomain-cluster-1 -- ping -c 4 172.16.1.2
```

Switch to *cluster2*:

```bash
export KUBECONFIG=$KUBECONFIG2
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-floating-kernel2vxlan2kernel-floating-interdomain-cluster-2 -- ping -c 4 172.16.1.3
```

## Cleanup

1. Cleanup resources for *cluster1*:
```bash
export KUBECONFIG=$KUBECONFIG1
```
```bash
kubectl delete ns ns-floating-kernel2vxlan2kernel-floating-interdomain-cluster-1
```

2. Cleanup resources for *cluster2*:
```bash
export KUBECONFIG=$KUBECONFIG2
```
```bash
kubectl delete ns ns-floating-kernel2vxlan2kernel-floating-interdomain-cluster-2
```
