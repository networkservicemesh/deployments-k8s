# Floating interdomain kernel2wireguard2kernel example

This example shows that NSC can reach NSE registered in floating registry.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `wireguard` mechanism to connect with each other.


Important points:
- nsc deploys on cluster1 and requests network service from *cluster3*.
- nse deploys on cluster2 and registers itself in *cluster3* with IP payload.


## Requires

Make sure that you have completed steps from [interdomain](../../)

## Run

**1. Deploy endpoint on cluster2**

```bash
export KUBECONFIG=$KUBECONFIG2
```

```bash
kubectl create ns ns-floating-kernel2wireguard2kernel
```

Deploy NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_Kernel2Wireguard2Kernel/cluster2?ref=c5ec23c2ddf369af8ef30204f3c39a216f6110c5
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-floating-kernel2wireguard2kernel
```

Find NSE pod by labels:
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-floating-kernel2wireguard2kernel --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
[[ ! -z $NSE ]]
```

**2. Deploy client on cluster1**

```bash
export KUBECONFIG=$KUBECONFIG1
```

```bash
kubectl create ns ns-floating-kernel2wireguard2kernel
```

Deploy NSC:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_Kernel2Wireguard2Kernel/cluster1?ref=c5ec23c2ddf369af8ef30204f3c39a216f6110c5
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=alpine -n ns-floating-kernel2wireguard2kernel
```


Find NSC pod by labels:
```bash
NSC=$(kubectl get pods -l app=alpine -n ns-floating-kernel2wireguard2kernel --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
[[ ! -z $NSC ]]
```

**3. Check connectivity**

Switch to *cluster1*:

```bash
export KUBECONFIG=$KUBECONFIG1
```

```bash
kubectl exec ${NSC} -n ns-floating-kernel2wireguard2kernel -- ping -c 4 172.16.1.2
```

Switch to *cluster2*:

```bash
export KUBECONFIG=$KUBECONFIG2
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-floating-kernel2wireguard2kernel -- ping -c 4 172.16.1.3
```

## Cleanup

1. Cleanup resources for *cluster1*:
```bash
export KUBECONFIG=$KUBECONFIG1
```
```bash
kubectl delete ns ns-floating-kernel2wireguard2kernel
```

2. Cleanup resources for *cluster2*:
```bash
export KUBECONFIG=$KUBECONFIG2
```
```bash
kubectl delete ns ns-floating-kernel2wireguard2kernel
```
