## Requires

- [spire](../spire)

## Includes

- [VFIO Connection](../use-cases/Vfio2Noop)
- [Kernel Connection](../use-cases/SriovKernel2Noop)

## Run

1. Create ns for deployments:
```bash
kubectl create ns nsm-system
```

Apply NSM resources for basic tests:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/sriov?ref=9ef72c46c675de4d0935dc473ab3f8df175e99b0
```

## Cleanup

To free resources follow the next command:
```bash
kubectl delete mutatingwebhookconfiguration --all
kubectl delete ns nsm-system
```
