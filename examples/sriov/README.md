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
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/sriov?ref=fd48c50457604bb73ed43f0d92fcaf94e33d3bc3
```

## Includes

- [Kernel2RVlanInternal](../use-cases/Kernel2RVlanInternal)
- [Kernel2RVlanBreakout](../use-cases/Kernel2RVlanBreakout)
- [Kernel2RVlanMultiNS](../use-cases/Kernel2RVlanMultiNS)

## Cleanup

To free resources follow the next commands:

```bash
kubectl delete mutatingwebhookconfiguration nsm-mutating-webhook
kubectl delete ns nsm-system
```
