## Requires

- [spire](../spire)

## Includes

- [VFIO Connection](../use-cases/Vfio2Noop)
- [Kernel Connection](../use-cases/SriovKernel2Noop)

## Run

1. Create ns for deployments:
```bash
kubectl create ns nsm-system
```

2. Register `nsm-system` namespace in spire:
```bash
kubectl exec -n spire spire-server-0 -- \
/opt/spire/bin/spire-server entry create \
-spiffeID spiffe://example.org/ns/nsm-system/sa/default \
-parentID spiffe://example.org/ns/spire/sa/spire-agent \
-selector k8s:ns:nsm-system \
-selector k8s:sa:default
```

3. Register `registry-k8s-sa` in spire:
```bash
kubectl exec -n spire spire-server-0 -- \
/opt/spire/bin/spire-server entry create \
-spiffeID spiffe://example.org/ns/nsm-system/sa/registry-k8s-sa \
-parentID spiffe://example.org/ns/spire/sa/spire-agent \
-selector k8s:ns:nsm-system \
-selector k8s:sa:registry-k8s-sa
```

4. Apply NSM resources for basic tests:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/sriov?ref=35ffecc5f0bdb88f80bbce0a4423cf2ab9369540
```

## Cleanup

To free resources follow the next command:
```bash
kubectl delete mutatingwebhookconfiguration --all
kubectl delete ns nsm-system
```