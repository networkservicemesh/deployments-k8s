# NSM over interdomain vL3 scaled from zero network

## Description

This example shows how to configure autoscaled vL3-network for interdomain.

The diagram is presented below ([source](https://drive.google.com/file/d/1Fv0g6N-wqlA1VKoeNAoysb6W3JAn8OTe/view?usp=sharing)).

![NSM kernel2kernel Diagram](./floating_vl3_autoscale.svg "NSM Kernel2Kernel Scheme")

## Requires

Make sure that you have completed steps from [interdomain](../../)

## Run

**1. Deploy**

1.1. Switch context to the *floating domain*.

```bash
export KUBECONFIG=$KUBECONFIG3
```

1.2. Start **vl3 ipam** and register **vl3 network service** in the *floating domain*.


Note: *By default ipam prefix is `172.16.0.0/16` and client prefix len is `24`. We also have two vl3 nses in this example. So we expect to have two vl3 addresses: `172.16.0.0` and `172.16.1.0` that should be accessible by each client.*


```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_vl3-scale-from-zero/cluster3?ref=5218781f91abfafe3835ede05011ee764f17e3ac
```

1.3. Switch context to the *cluster1*.

```bash
export KUBECONFIG=$KUBECONFIG1
```

1.6. Start **nse-supplier-k8s** and client in the *cluster1*.

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_vl3-scale-from-zero/cluster1?ref=5218781f91abfafe3835ede05011ee764f17e3ac
```

1.7. Switch context to the *cluster2*.

```bash
export KUBECONFIG=$KUBECONFIG2
```

1.10. Start **nse-supplier-k8s** and client in the *cluster2*.

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_vl3-scale-from-zero/cluster2?ref=5218781f91abfafe3835ede05011ee764f17e3ac
```

**2. Get assigned IP addresses**

2.1. Find NSC in the *cluster2*:

```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-floating-vl3-scale-from-zero
```
```bash
nsc2=$(kubectl get pods -l app=alpine -n ns-floating-vl3-scale-from-zero --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

2.2. Switch context to the *cluster1*.

```bash
export KUBECONFIG=$KUBECONFIG1
```

2.3. Find NSC in the *cluster1*:

```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-floating-vl3-scale-from-zero
```
```bash
nsc1=$(kubectl get pods -l app=alpine -n ns-floating-vl3-scale-from-zero --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

**3. Check connectivity**

3.1. Get assigned IP address from the vl3-NSE for the NSC2 and ping the remote client (NSC1):
```bash
ipAddr2=$(kubectl --kubeconfig=$KUBECONFIG2 exec -n ns-floating-vl3-scale-from-zero $nsc2 -- ifconfig nsm-1)
ipAddr2=$(echo $ipAddr2 | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
kubectl exec $nsc1 -n ns-floating-vl3-scale-from-zero -- ping -c 4 $ipAddr2
```

3.2. Ping vl3 nses:
```bash
kubectl exec $nsc1 -n ns-floating-vl3-scale-from-zero -- ping -c 4 172.16.0.0
kubectl exec $nsc1 -n ns-floating-vl3-scale-from-zero -- ping -c 4 172.16.1.0
```

3.3. Switch to the *cluster2*
```bash
export KUBECONFIG=$KUBECONFIG2
```

3.4. Get assigned IP address from the vl3-NSE for the NSC1 and ping the remote client (NSC2):
```bash
ipAddr1=$(kubectl --kubeconfig=$KUBECONFIG1 exec -n ns-floating-vl3-scale-from-zero $nsc1 -- ifconfig nsm-1)
ipAddr1=$(echo $ipAddr1 | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
kubectl exec $nsc2 -n ns-floating-vl3-scale-from-zero -- ping -c 4 $ipAddr1
```

3.5. Ping vl3 nses:
```bash
kubectl exec $nsc2 -n ns-floating-vl3-scale-from-zero -- ping -c 4 172.16.0.0
kubectl exec $nsc2 -n ns-floating-vl3-scale-from-zero -- ping -c 4 172.16.1.0
```

## Cleanup

1. Cleanup floating domain:

```bash
export KUBECONFIG=$KUBECONFIG3 && kubectl delete -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_vl3-scale-from-zero/cluster3?ref=5218781f91abfafe3835ede05011ee764f17e3ac
```

2. Cleanup cluster2 domain:

```bash
export KUBECONFIG=$KUBECONFIG2 && kubectl delete -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_vl3-scale-from-zero/cluster2?ref=5218781f91abfafe3835ede05011ee764f17e3ac
```

3. Cleanup cluster1 domain:

```bash
export KUBECONFIG=$KUBECONFIG1 && kubectl delete -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_vl3-scale-from-zero/cluster1?ref=5218781f91abfafe3835ede05011ee764f17e3ac
```
