# Client requests for CoreDNS service

This example demonstrates how an external client configures DNS from the connected endpoint. 
Note: NSE provides DNS by itself. Also, NSE could provide configs for any other external DNS servers(that are not located as sidecar with NSE).

## Requires

Make sure that you have completed steps from [features](../)

## Run

Deploy alpine and nse
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/dns?ref=c24bb991afd5b625d7a75d58c37b7497dfb9f4ae
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod dnsutils -n ns-dns
```
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=nse-kernel -n ns-dns
```

Ping from dnsutils to NSE by domain name:
```bash
kubectl exec pods/dnsutils -c dnsutils -n ns-dns -- nslookup -norec -nodef my.coredns.service
```
```bash
kubectl exec pods/dnsutils -c dnsutils -n ns-dns -- ping -c 4 my.coredns.service
```

Validate that default DNS server is working:
```bash
kubectl exec pods/dnsutils -c dnsutils -n ns-dns -- dig kubernetes.default A kubernetes.default AAAA | grep "kubernetes.default.svc.cluster.local"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-dns
```
