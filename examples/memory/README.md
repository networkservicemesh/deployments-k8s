# Memory examples

Memory example contains setup and tear down logic with default NSM infrastructure and memroy based registry backend.

## Requires

- [spire](../spire)

## Includes

- [Memif to Memif Connection](../use-cases/Memif2Memif)
- [Kernel to Kernel Connection](../use-cases/Kernel2Kernel)
- [Kernel to VXLAN to Kernel Connection](../use-cases/Kernel2Vxlan2Kernel)

## Run

Create ns for deployments:
```bash
kubectl create ns nsm-system
```

Apply NSM resources for basic tests:

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/memory?ref=5cf6d4f970dfd693668761af1de7c43c0e96ae05
```

## Cleanup

```bash
kubectl delete ns nsm-system
```
