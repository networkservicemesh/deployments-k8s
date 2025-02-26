# Client requests for CoreDNS service

This example demonstrates how an external client configures DNS from the connected endpoint. 
Note: NSE provides DNS by itself. Also, NSE could provide configs for any other external DNS servers(that are not located as sidecar with NSE).

## Requires

Make sure that you have completed steps from [features](../)

## Run

Deploy alpine and nse
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/dns?ref=3dc3884a63b990754aaca0271531a67f54c51904
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
