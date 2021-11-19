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
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/memory?ref=1ade24bec86b28b2ad8130deea100e77b1b059c9
```

## Cleanup

```bash
kubectl delete ns nsm-system
```
