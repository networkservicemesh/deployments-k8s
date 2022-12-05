# Test kernel to vxlan to kernel connection

This example shows that NSC and NSE on the different clusters could find and work with each other.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [interdomain](../../)

## Run

**1. Deploy endpoint on cluster2**

```bash
export KUBECONFIG=$KUBECONFIG2
```

```bash
kubectl create ns ns-interdomain-kernel2vxlan2kernel
```

Deploy NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/interdomain_Kernel2Vxlan2Kernel/cluster2?ref=f1fd4b5b111467399cda961859640efdd3331e8d
```

Find NSE pod by labels:
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-interdomain-kernel2vxlan2kernel --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
[[ ! -z $NSE ]]
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-interdomain-kernel2vxlan2kernel
```

**2. Deploy client on cluster1**

```bash
export KUBECONFIG=$KUBECONFIG1
```

```bash
kubectl create ns ns-interdomain-kernel2vxlan2kernel
```

Deploy client:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/interdomain_Kernel2Vxlan2Kernel/cluster1?ref=f1fd4b5b111467399cda961859640efdd3331e8d
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=alpine -n ns-interdomain-kernel2vxlan2kernel
```

Find client pod by labels:
```bash
NSC=$(kubectl get pods -l app=alpine -n ns-interdomain-kernel2vxlan2kernel --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
[[ ! -z $NSC ]]
```

**3. Check connectivity**

Switch to *cluster1*:

```bash
export KUBECONFIG=$KUBECONFIG1
```

```bash
kubectl exec ${NSC} -n ns-interdomain-kernel2vxlan2kernel -- ping -c 4 172.16.1.2
```

Switch to *cluster2*:

```bash
export KUBECONFIG=$KUBECONFIG2
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-interdomain-kernel2vxlan2kernel -- ping -c 4 172.16.1.3
```

## Cleanup

1. Cleanup resources for *cluster1*:
```bash
export KUBECONFIG=$KUBECONFIG1
```
```bash
kubectl delete ns ns-interdomain-kernel2vxlan2kernel
```

2. Cleanup resources for *cluster2*:
```bash
export KUBECONFIG=$KUBECONFIG2
```
```bash
kubectl delete ns ns-interdomain-kernel2vxlan2kernel
```
