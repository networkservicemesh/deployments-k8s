# Floating interdomain DNS example

This example shows how DNS works for the client if the dns server (NSE) is located on another cluster.
The NSE is registered in the floating registry.
Note: NSE provides DNS by itself. Also, NSE could provide configs for any other external DNS servers(that are not located as sidecar with NSE).

## Requires

Make sure that you have completed steps from [multicluster](../../)

## Run

**1. Deploy network service on cluster3**

Deploy NetworkService:
```bash
kubectl --kubeconfig=$KUBECONFIG3 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_dns/cluster3?ref=504e36559259db1cb5ff4a555ca29fb4da02a3e6
```

**2. Deploy endpoint on cluster2**

Deploy NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_dns/cluster2?ref=504e36559259db1cb5ff4a555ca29fb4da02a3e6
```

**3. Deploy client on cluster1**

Deploy client:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/floating_dns/cluster1?ref=504e36559259db1cb5ff4a555ca29fb4da02a3e6
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=5m pod -l app=dnsutils -n ns-floating-dns
```

**4. Check connectivity**

Find dns server using nslookup: 
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/dnsutils -c dnsutils -n ns-floating-dns -- nslookup -norec -nodef my.coredns.service
```

Ping from dnsutils to NSE by domain name:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/dnsutils -c dnsutils -n ns-floating-dns -- ping -c 4 my.coredns.service
```

Validate that the default DNS server is working:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/dnsutils -c dnsutils -n ns-floating-dns -- dig kubernetes.default A kubernetes.default AAAA | grep "kubernetes.default.svc.cluster.local"
```

## Cleanup

1. Cleanup resources for *cluster1*:
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete ns ns-floating-dns
```

2. Cleanup resources for *cluster2*:
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete ns ns-floating-dns
```

3. Cleanup resources for *cluster3*:
```bash
kubectl --kubeconfig=$KUBECONFIG3 delete ns ns-floating-dns
```
