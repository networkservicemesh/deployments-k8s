# Floating VL3 DNS example

## Description

This example show how DNS works over VL3 network.

## Requires

Make sure that you have completed steps from [multicluster](../../)

## Run

**1. Deploy**

1.1. Start **vl3 ipam** and register **vl3 network service** in the *floating domain*.
Note: *By default ipam prefix is `172.16.0.0/16` and client prefix len is `24`. We also have two vl3 nses in this example. So we expect to have two vl3 addresses: `172.16.0.0` and `172.16.1.0` that should be accessible by each client.*

```bash
kubectl --kubeconfig=$KUBECONFIG3 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_vl3-dns/cluster3?ref=7a824cb44e67326f44d18cae79d594ba175357ca
```

1.2. Deploy a vl3-NSE and a client on the cluster1:

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_vl3-dns/cluster1?ref=7a824cb44e67326f44d18cae79d594ba175357ca
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=5m pod -l app=alpine -n ns-floating-vl3-dns
```

1.3. Deploy a vl3-NSE and a client on the cluster2:

```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_vl3-dns/cluster2?ref=7a824cb44e67326f44d18cae79d594ba175357ca
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=5m pod -l app=alpine -n ns-floating-vl3-dns
```

**2. Get assigned endpoint names**

2.1. Find NSC and NSE in the *cluster1*:

```bash
nsc1=$(kubectl --kubeconfig=$KUBECONFIG1 get pods -l app=alpine -n ns-floating-vl3-dns --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
nse1=$(kubectl --kubeconfig=$KUBECONFIG1 get pods -l app=nse-vl3-vpp -n ns-floating-vl3-dns --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

2.2. Find NSC and NSE in the *cluster2*:

```bash
nsc2=$(kubectl --kubeconfig=$KUBECONFIG2 get pods -l app=alpine -n ns-floating-vl3-dns --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
nse2=$(kubectl --kubeconfig=$KUBECONFIG2 get pods -l app=nse-vl3-vpp -n ns-floating-vl3-dns --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

**3. Check connectivity**

3.1. NSC1 pings another client and endpoints via DNS:

```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/alpine-1 -n ns-floating-vl3-dns -- ping -c2 -i 0.5 $nsc2.floating-vl3-dns.my.cluster3. -4
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/alpine-1 -n ns-floating-vl3-dns -- ping -c2 -i 0.5 $nse2.floating-vl3-dns.my.cluster3. -4
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/alpine-1 -n ns-floating-vl3-dns -- ping -c2 -i 0.5 $nse1.floating-vl3-dns.my.cluster3. -4
```

3.2. NSC2 pings another client and endpoints via DNS:

```bash
kubectl --kubeconfig=$KUBECONFIG2 exec pods/alpine-2 -n ns-floating-vl3-dns -- ping -c2 -i 0.5 $nsc1.floating-vl3-dns.my.cluster3. -4
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec pods/alpine-2 -n ns-floating-vl3-dns -- ping -c2 -i 0.5 $nse1.floating-vl3-dns.my.cluster3. -4
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec pods/alpine-2 -n ns-floating-vl3-dns -- ping -c2 -i 0.5 $nse2.floating-vl3-dns.my.cluster3. -4
```

## Cleanup

1. Cleanup floating domain:
```bash
kubectl --kubeconfig=$KUBECONFIG3 delete -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_vl3-dns/cluster3?ref=7a824cb44e67326f44d18cae79d594ba175357ca
```

2. Cleanup cluster2 domain:
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_vl3-dns/cluster2?ref=7a824cb44e67326f44d18cae79d594ba175357ca
```

3. Cleanup cluster1 domain:
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_vl3-dns/cluster1?ref=7a824cb44e67326f44d18cae79d594ba175357ca
```
