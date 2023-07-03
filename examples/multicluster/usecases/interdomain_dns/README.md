# Interdomain DNS example

This example shows how DNS works for the client if the dns server (NSE) is located on another cluster.
Note: NSE provides DNS by itself. Also, NSE could provide configs for any other external DNS servers(that are not located as sidecar with NSE).

## Requires

Make sure that you have completed steps from [multicluster](../../)

## Run

**1. Deploy endpoint on cluster2**

Deploy NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/interdomain_dns/cluster2?ref=4e2b5e817b0141a33e138b4c3f1a325b1ec0d4fb
```

**2. Deploy client on cluster1**

Deploy client:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/interdomain_dns/cluster1?ref=4e2b5e817b0141a33e138b4c3f1a325b1ec0d4fb
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=5m pod -l app=dnsutils -n ns-interdomain-dns
```

**3. Check connectivity**

Find dns server using nslookup: 
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/dnsutils -c dnsutils -n ns-interdomain-dns -- nslookup -norec -nodef my.coredns.service
```

Ping from dnsutils to NSE by domain name:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/dnsutils -c dnsutils -n ns-interdomain-dns -- ping -c 4 my.coredns.service
```

Validate that the default DNS server is working:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/dnsutils -c dnsutils -n ns-interdomain-dns -- dig kubernetes.default A kubernetes.default AAAA | grep "kubernetes.default.svc.cluster.local"
```

## Cleanup

1. Cleanup resources for *cluster1*:
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete ns ns-interdomain-dns
```

2. Cleanup resources for *cluster2*:
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete ns ns-interdomain-dns
```
