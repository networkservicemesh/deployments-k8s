# Test kernel to kernel connection with annotated namespace

This example shows that NSM annotations applied to namespace will be applied to the pods within this namespace.  

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.


## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace and deploy NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/annotated-namespace?ref=1dc475fd944262a817a6880a2f8dd15de8fcf465
```

Wait for NSE to be ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-annotated-namespace
```

Annotate namespace with NSM annotation:
```bash
kubectl annotate ns ns-annotated-namespace networkservicemesh.io=kernel://annotated-namespace/nsm-1
```

Apply client patch:
```bash
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/1dc475fd944262a817a6880a2f8dd15de8fcf465/examples/features/annotated-namespace/client.yaml
```

Wait for client to be ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-annotated-namespace
```

Check if client ID is properly generated
```bash
kubectl logs deployments/alpine -n ns-annotated-namespace -c cmd-nsc-init | grep -c '\[id:alpine-.*-0\]'
```

Ping from NSC to NSE:
```bash
kubectl exec deployments/alpine -n ns-annotated-namespace -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-annotated-namespace -- ping -c 4 172.16.1.101
```


## Cleanup

Delete ns:
```bash
kubectl delete ns ns-annotated-namespace
```
