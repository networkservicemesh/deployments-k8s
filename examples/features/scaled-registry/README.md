# Test scaled registry-k8s

This example shows that registry-k8s can be easly scaled. NSEs can Register and Unregister themselves in any of
the registries.

## Requires

Make sure that you have completed steps from [basic](../../basic) setup.

## Run

Deploy NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/scaled-registry?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Wait for NSE to be ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-scaled-registry
```

Find NSE pod by label:
```bash
NSE=$(kubectl get pod -n ns-scaled-registry --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' -l app=nse-kernel)
```

Check registered NSE in `etcd`
```bash
kubectl get nses -A | grep $NSE
```

Delete current instance of registry-k8s
```bash
kubectl scale --replicas=0 deployments/registry-k8s -n nsm-system
```

Wait for registry-k8s to be deleted
```bash
kubectl wait --for=delete --timeout=1m pod -l app=registry -n nsm-system
```

Check registered NSE in `etcd` after registry-k8s instance deletion
```bash
kubectl get nses -A | grep $NSE
```

Deploy two new instances of registry-k8s
```bash
kubectl scale --replicas=2 deployments/registry-k8s -n nsm-system
```

Wait for the new registry-k8s instances to be ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=registry -n nsm-system
```

Delete NSE (it unregisters itself on deletion)
```bash
kubectl scale --replicas=0 deployments/nse-kernel -n ns-scaled-registry
```

Check there is no any NSEs in `etcd` after NSE unregisters itself through the new registries
```bash
kubectl get nses -A | grep $NSE
if [[ "$?" == "1" ]]; then echo OK; else echo "nse entry still exists"; false; fi
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-scaled-registry
```

Scale registry-k8s back to 1 replica
```bash
kubectl scale --replicas=1 deployments/registry-k8s -n nsm-system
```