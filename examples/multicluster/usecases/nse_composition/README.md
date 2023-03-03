# Floating interdomain kernel2vxlan2kernel example

This example shows that NSC can reach NSE registered in floating registry.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

NSE is registering in the floating registry.


## Requires

Make sure that you have completed steps from [interdomain](../../)

## Run

**1. Deploy network service on cluster3**

Deploy NS:
```bash
kubectl --kubeconfig=$KUBECONFIG3 apply -k cluster3
```

**2. Deploy endpoint on cluster2**

Deploy NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k cluster2
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-nse-composition
```

Find NSE pod by labels:
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-nse-composition --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
[[ ! -z $NSE ]]
```

**2. Deploy client on cluster1**

Deploy NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k cluster1
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=alpine -n ns-nse-composition
```

Find NSC pod by labels:
```bash
NSC=$(kubectl get pods -l app=alpine -n ns-nse-composition --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
[[ ! -z $NSC ]]
```

**3. Check connectivity**

Switch to *cluster1*:

```bash
kubectl --kubeconfig=$KUBECONFIG1 exec ${NSC} -n ns-nse-composition -- ping -c 4 172.16.1.2
```

Switch to *cluster2*:

```bash
export KUBECONFIG=$KUBECONFIG2
```

Ping from NSE to NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec ${NSE} -n ns-nse-composition -- ping -c 4 172.16.1.3
```

## Cleanup

1. Cleanup resources for *cluster1*:
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete ns ns-nse-composition
```

2. Cleanup resources for *cluster2*:
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete ns ns-nse-composition
```

3. Cleanup resources for *cluster3*:
```bash
kubectl --kubeconfig=$KUBECONFIG3 delete ns ns-nse-composition
```
