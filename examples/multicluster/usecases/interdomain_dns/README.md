# Interdomain DNS example

This example shows how DNS works for the client if the dns server (NSE) is located on another cluster.
Note: NSE provides DNS by itself. Also, NSE could provide configs for any other external DNS servers(that are not located as sidecar with NSE).

## Requires

Make sure that you have completed steps from [multicluster](../../)

## Run

**1. Deploy endpoint on cluster2**

Deploy NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/interdomain_dns/cluster2?ref=d9cfd5bca62e13111c88617c3266aaa6b15faf30
```

Find NSE pod by labels:
```bash
NSE=$(kubectl --kubeconfig=$KUBECONFIG2 get pods -l app=nse-kernel -n ns-interdomain-dns --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
[[ ! -z $NSE ]]
```

**2. Deploy client on cluster1**

Deploy client:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/usecases/interdomain_dns/cluster1?ref=d9cfd5bca62e13111c88617c3266aaa6b15faf30
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=5m pod -l app=dnsutils -n ns-interdomain-dns
```

Find client pod by labels:
```bash
NSC=$(kubectl --kubeconfig=$KUBECONFIG1 get pods -l app=dnsutils -n ns-interdomain-dns --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
[[ ! -z $NSC ]]
```

**3. Check connectivity**

Find dns server using nslookup: 
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec ${NSC} -c dnsutils -n ns-interdomain-dns -- nslookup -norec -nodef my.coredns.service
```

Ping from dnsutils to NSE by domain name:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec ${NSC} -c dnsutils -n ns-interdomain-dns -- ping -c 4 my.coredns.service
```

Validate that the default DNS server is working:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec ${NSC} -c dnsutils -n ns-interdomain-dns -- dig kubernetes.default A kubernetes.default AAAA | grep "kubernetes.default.svc.cluster.local"
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
