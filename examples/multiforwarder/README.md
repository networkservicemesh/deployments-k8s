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

2. Apply NSM resources for multiforwarder tests:
```bash
if [[ "${CALICO}" == "on" ]]; then # calico
  kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multiforwarder/calico?ref=6b88da39e40e64d665add469616315a9c289ecdb
else
  kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multiforwarder/base?ref=6b88da39e40e64d665add469616315a9c289ecdb
fi
```

## Cleanup

Delete ns:
```bash
kubectl delete ns nsm-system
```
