# Feature IPAM Policies

This example shows how NSM Endpoint can use different IPAM policies to manage IP context of connections.

At this moment only NSEs have two IPAM policies:

1. `default` IPAM Policy accepts any address and route sent by NSM client.

2. `strict` IPAM Policy checks `source` and `destination` addresses of NSC's IP context and resets it if any of the 
addresses do not belong to NSE's IP Pool.

## Requires

Make sure that you have completed steps from [basic](../../basic) setup.

## Run

Deploy the client and the first NSE with CIDR `172.16.1.0/31` and `default` IPAM Policy:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/ipam-policies?ref=ab36042ccc72c683a5048b919aece1badbd5b33e
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-ipam-policies
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=first-nse -n ns-ipam-policies
```

Ping the first NSE from the client:
```bash
kubectl exec pods/alpine -n ns-ipam-policies -- ping -c 4 172.16.1.0
```

Ping the client from the first NSE:
```bash
kubectl exec pods/first-nse -n ns-ipam-policies -- ping -c 4 172.16.1.1
```

Delete the first NSE:
```bash
kubectl delete pod -l app=first-nse -n ns-ipam-policies
```

Apply the second NSE with CIDR `172.16.2.0/31` and `strict` IPAM Policy:
```bash
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/ab36042ccc72c683a5048b919aece1badbd5b33e/examples/features/ipam-policies/second-nse.yaml -n ns-ipam-policies
```

Ping the second NSE from the client:
```bash
kubectl exec pods/alpine -n ns-ipam-policies -- ping -c 4 172.16.2.0
```

Ping the client from the second NSE:
```bash
kubectl exec pods/second-nse -n ns-ipam-policies -- ping -c 4 172.16.2.1
```

Check routes on the client. They should contain only the routes from CIDR `172.16.2.0/31`:
```bash
routes=$(kubectl exec pods/alpine -n ns-ipam-policies -- ip r show dev nsm-1 | xargs) # Use xargs here just to trim whitespaces in the routes
if [[ "$routes" != "172.16.2.0 dev nsm-1" ]]; then
    echo "routes on the client are invalid"
    exit
fi
```


## Cleanup

Delete ns:
```bash
kubectl delete ns ns-ipam-policies
```
