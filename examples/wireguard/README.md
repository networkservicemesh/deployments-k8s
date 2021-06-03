# Wireguard examples

Contain basic setup for NSM that includes `nsmgr`, `forwarder-vpp`, `registry-k8s`. This setup can be used to check mechanisms combination or some kind of NSM [features](../features).

## Requires

- [spire](../spire)

## Includes

- [Kernel to Wireguard to Kernel Connection](../use-cases/Kernel2Wireguard2Kernel)
- [Memif to Wireguard to Memif Connection](../use-cases/Memif2Wireguard2Memif)
- [Kernel to Wireguard to Memif Connection](../use-cases/Kernel2Wireguard2Memif)
- [Memif to Wireguard to Kernel Connection](../use-cases/Memif2Wireguard2Kernel)

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

4. Apply NSM resources for wireguard tests:

```bash
kubectl apply -k .
```

## Cleanup

To free resouces follow the next command:

```bash
kubectl delete mutatingwebhookconfiguration --all
kubectl delete ns nsm-system
```