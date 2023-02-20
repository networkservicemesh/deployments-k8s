## Requires

- [spire](../spire/single_cluster)

## Includes

- [VFIO Connection](../use-cases/Vfio2Noop)
- [Kernel Connection](../use-cases/SriovKernel2Noop)

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
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/sriov?ref=65044a43b38a7637139a8d69ba1b7f03ff69ee79
```

## Cleanup

To free resources follow the next commands:

```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl delete mutatingwebhookconfiguration ${WH}
kubectl delete ns nsm-system
```
