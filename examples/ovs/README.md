# OVS examples

Contain basic setup for NSM that includes `nsmgr`, `forwarder-ovs`, `registry-k8s`, `admission-webhook-k8s`. This setup can be used to check mechanisms combination or some kind of NSM [features](../features).

## Requires

- [spire](../spire)

## Includes

- [Kernel to Kernel Connection](../use-cases/Kernel2Kernel)
- [Kernel to Kernel Connection over VLAN Trunking](../use-cases/Kernel2KernelVLAN)
- [SmartVF to SmartVF Connection](../use-cases/SmartVF2SmartVF)
- [Admission webhook SmartVF example](../features/webhook-smartvf)

## SR-IOV config

These tests require [SR-IOV config](../../doc/SRIOV_config.md) created on both `master` and `worker` nodes and located
under `/var/lib/networkservicemesh/smartnic.config`.

Required service domains and capabilities for the `master` node are:
```yaml
    capabilities:
      - 100G
    serviceDomains:
      - worker.domain
```
For the `worker` node:
```yaml
    capabilities:
      - 100G
    serviceDomains:
      - master.domain
```

## Run

1. Create ns for deployments:
```bash
kubectl create ns nsm-system
```

2. Apply NSM resources for basic tests:

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/ovs?ref=86c5e6881c62beedbe75a8c97065915133a73ce0
```

## Cleanup

To free resouces follow the next command:

```bash
kubectl delete mutatingwebhookconfiguration --all
kubectl delete ns nsm-system
```
