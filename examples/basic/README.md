# Basic examples

Contain basic setup for NSM that includes `nsmgr`, `forwarder-vpp`, `registry-k8s`. This setup can be used to check mechanisms combination or some kind of NSM [features](../features).

## Requires

- [spire](../spire)

## Includes

- [Memif to Memif Connection](../use-cases/Memif2Memif)
- [Kernel to Kernel Connection](../use-cases/Kernel2Kernel)
- [Kernel to Memif Connection](../use-cases/Kernel2Memif)
- [Memif to Kernel Connection](../use-cases/Memif2Kernel)
- [Kernel to VXLAN to Kernel Connection](../use-cases/Kernel2Vxlan2Kernel)
- [Memif to VXLAN to Memif Connection](../use-cases/Memif2Vxlan2Memif)
- [Kernel to VXLAN to Memif Connection](../use-cases/Kernel2Vxlan2Memif)
- [Memif to VXLAN to Kernel Connection](../use-cases/Memif2Vxlan2Kernel)
- [Kernel to Wireguard to Kernel Connection](../use-cases/Kernel2Wireguard2Kernel)
- [Memif to Wireguard to Memif Connection](../use-cases/Memif2Wireguard2Memif)
- [Kernel to Wireguard to Memif Connection](../use-cases/Kernel2Wireguard2Memif)
- [Memif to Wireguard to Kernel Connection](../use-cases/Memif2Wireguard2Kernel)

## Run

1. Create ns for deployments:
```bash
kubectl create ns nsm-system
```

2. Apply NSM resources for basic tests:

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/basic?ref=5f3d2f4f5c0bf02af1b8e50bee23909ca7c3d217
```

## Cleanup

To free resouces follow the next command:

```bash
kubectl delete mutatingwebhookconfiguration --all
kubectl delete ns nsm-system
```
