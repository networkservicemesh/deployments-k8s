# Multiforwarder examples
These examples include 2 forwarders - _forwarder-vpp_ and _forwarder-sriov_
SR-IOV uses VLAN tagged connections

## Requires

- [spire](../spire/single_cluster)

## SR-IOV config

These tests require [SR-IOV config](../../doc/SRIOV_config.md) created on both `master` and `worker` nodes and located
under `/var/lib/networkservicemesh/sriov.config`.

Required service domains and capabilities for the `master` node are:
```yaml
    capabilities:
      - 10G
    serviceDomains:
      - worker.domain
```
For the `worker` node:
```yaml
    capabilities:
      - 10G
    serviceDomains:
      - master.domain
```

## Run

Apply NSM resources for basic tests:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multiforwarder?ref=ecc38f6cd7d2932363e20a893dc230198c08a4a9
```

Wait for admission-webhook-k8s:

```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```

## Includes

- [VLAN tagged VFIO Connection](../use-cases/Vfio2NoopVlanTag)
- [VLAN tagged Kernel Connection](../use-cases/SriovKernel2NoopVlanTag)
- [Memif to Memif Connection](../use-cases/Memif2Memif)
- [Kernel to Kernel Connection](../use-cases/Kernel2Kernel)
- [Kernel to Ethernet to Kernel Connection](../use-cases/Kernel2Ethernet2Kernel)
- [Kernel to Kernel Connection & VLAN tagged VFIO Connection](../use-cases/Kernel2Kernel_Vfio2NoopVlanTag)
- [Kernel to Ethernet to Kernel Connection & VLAN tagged VFIO Connection](../use-cases/Kernel2Ethernet2Kernel_Vfio2NoopVlanTag)


## Cleanup

To free resources follow the next commands:

```bash
kubectl delete mutatingwebhookconfiguration nsm-mutating-webhook
kubectl delete ns nsm-system
```
