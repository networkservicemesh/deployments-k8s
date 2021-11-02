## Requires

- [spire](../spire)

## Includes

- [VFIO Connection](../use-cases/Vfio2Noop)
- [Kernel Connection](../use-cases/SriovKernel2Noop)
- [Memif to Memif Connection](../use-cases/Memif2Memif)
- [Kernel to Kernel Connection](../use-cases/Kernel2Kernel)
- [Kernel to VXLAN to Kernel Connection](../use-cases/Kernel2Vxlan2Kernel)
- [Kernel to Kernel Connection & VFIO Connection](../use-cases/Kernel2Kernel&Vfio2Noop)
- [Kernel to VXLAN to Kernel Connection & VFIO Connection](../use-cases/Kernel2Vxlan2Kernel&Vfio2Noop)

## Run

1. Create ns for deployments:
```bash
kubectl create ns nsm-system
```

Apply NSM resources for basic tests:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multiforwarder?ref=5ff452f280d000e5fbe600d76872fc7ffd7b9237
```

## Cleanup

Delete ns:
```bash
kubectl delete ns nsm-system
```
