# SR-IOV examples

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

Apply NSM resources for sriov tests:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/sriov?ref=56ef5a4ee6cc110793f17e5566c457356736b14b
```

## Includes

- [VFIO Connection](../use-cases/Vfio2Noop)
- [Kernel Connection](../use-cases/SriovKernel2Noop)

## Cleanup

To free resources follow the next commands:

```bash
kubectl delete mutatingwebhookconfiguration nsm-mutating-webhook
kubectl delete ns nsm-system
```
