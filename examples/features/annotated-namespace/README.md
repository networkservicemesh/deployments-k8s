# Test kernel to kernel connection with annotated namespace

This example shows that NSM annotations applied to namespace will be applied to the pods within this namespace.  

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.


## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace and deploy NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/annotated-namespace?ref=e35e6fbeb8f986246ff856264e150e0365734e10
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
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/e35e6fbeb8f986246ff856264e150e0365734e10/examples/features/annotated-namespace/client.yaml
```

Wait for client to be ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-annotated-namespace
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
