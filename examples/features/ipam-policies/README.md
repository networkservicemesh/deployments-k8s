# Feature IPAM Policies

This example shows how NSM Endpoint can use different IPAM policies to manage IP context of connections.

At this moment only NSEs have two IPAM policies:

1. `default` IPAM Policy accepts any address and route sent by NSM client.

2. `strict` IPAM Policy checks `source` and `destination` addresses of NSC's IP context and resets it if any of the 
addresses do not belong to NSE's IP Pool.

## Requires

Make sure that you have completed steps from [basic](../../basic) setup.

## Run

Deploy the client and the first NSE with CIDR `172.16.1.0/29` and `default` IPAM Policy:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/ipam-policies?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine-1 -n ns-ipam-policies
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine-2 -n ns-ipam-policies
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=first-nse -n ns-ipam-policies
```

Ping the first NSE from the first client:
```bash
kubectl exec pods/alpine-1 -n ns-ipam-policies -- ping -c 4 172.16.1.0 || kubectl exec pods/alpine-1 -n ns-ipam-policies -- ping -c 4 172.16.1.2
```

Ping the first NSE from the second client:
```bash
kubectl exec pods/alpine-2 -n ns-ipam-policies -- ping -c 4 172.16.1.0 || kubectl exec pods/alpine-2 -n ns-ipam-policies -- ping -c 4 172.16.1.2
```

Ping the first client from the first NSE:
```bash
kubectl exec pods/first-nse -n ns-ipam-policies -- ping -c 4 172.16.1.1
```

Ping the second client from the first NSE:
```bash
kubectl exec pods/first-nse -n ns-ipam-policies -- ping -c 4 172.16.1.3
```

Delete the first NSE:
```bash
kubectl delete pod -l app=first-nse -n ns-ipam-policies
```

Apply the second NSE with CIDR `172.16.2.0/29` and `strict` IPAM Policy:
```bash
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/0e8c3ce7819f0640d955dc1136a64ecff2ae8c56/examples/features/ipam-policies/second-nse.yaml -n ns-ipam-policies
```

Wait for application ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=second-nse -n ns-ipam-policies
```

Ping the second NSE from the first client:
```bash
kubectl exec pods/alpine-1 -n ns-ipam-policies -- ping -c 4 172.16.2.0 || kubectl exec pods/alpine-1 -n ns-ipam-policies -- ping -c 4 172.16.2.2
```

Ping the second NSE from the second client:
```bash
kubectl exec pods/alpine-2 -n ns-ipam-policies -- ping -c 4 172.16.2.0 || kubectl exec pods/alpine-2 -n ns-ipam-policies -- ping -c 4 172.16.2.2
```

Ping the first client from the NSE:
```bash
kubectl exec pods/second-nse -n ns-ipam-policies -- ping -c 4 172.16.2.1
```

Ping the second client from the NSE:
```bash
kubectl exec pods/second-nse -n ns-ipam-policies -- ping -c 4 172.16.2.3
```

Check routes on the clients. They should contain only the routes from CIDR `172.16.2.0/29`:
```bash
routes=$(kubectl exec pods/alpine-1 -n ns-ipam-policies -- ip r show dev nsm-1 | xargs) # Use xargs here just to trim whitespaces in the routes
if [[ "$routes" != "172.16.2.0 dev nsm-1" && "$routes" != "172.16.2.2 dev nsm-1" ]]; then
    echo "routes on the client are invalid"
    exit
fi
```

```bash
routes=$(kubectl exec pods/alpine-2 -n ns-ipam-policies -- ip r show dev nsm-2 | xargs) # Use xargs here just to trim whitespaces in the routes
if [[ "$routes" != "172.16.2.0 dev nsm-2" && "$routes" != "172.16.2.2 dev nsm-2" ]]; then
    echo "routes on the client are invalid"
    exit
fi
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-ipam-policies
```
