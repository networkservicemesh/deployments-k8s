# Basic examples

Basis example contains setup and tear down logic with default NSM infrastructure.

## Requires

- [spire](../spire)

## Includes

- [Kernel to VXLAN to Kernel Connection](../use-cases/Kernel2Vxlan2Kernel)

## Run

Create ns for deployments:
```bash
kubectl create ns nsm-system
```

Register `nsm-system` namespace in spire:

```bash
kubectl exec -n spire spire-server-0 -- \
/opt/spire/bin/spire-server entry create \
-spiffeID spiffe://example.org/ns/nsm-system/sa/default \
-parentID spiffe://example.org/ns/spire/sa/spire-agent \
-selector k8s:ns:nsm-system \
-selector k8s:sa:default
```

Register `registry-k8s-sa` in spire:

```bash
kubectl exec -n spire spire-server-0 -- \
/opt/spire/bin/spire-server entry create \
-spiffeID spiffe://example.org/ns/nsm-system/sa/registry-k8s-sa \
-parentID spiffe://example.org/ns/spire/sa/spire-agent \
-selector k8s:ns:nsm-system \
-selector k8s:sa:registry-k8s-sa
```
Apply NSM resources for basic tests:

```bash
kubectl apply -k .
```

```bash
kubectl port-forward service/jaeger -n observability 16686:16686&
kubectl port-forward service/prometheus -n observability 9090:9090&
```

## Cleanup

```bash
kubectl delete ns nsm-system
```
