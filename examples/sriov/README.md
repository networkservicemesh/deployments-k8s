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
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/sriov?ref=e12ea0991c29f6ae492e7c9bc1f0816576e1426b
```

## Cleanup

To free resources follow the next command:
```bash
kubectl delete mutatingwebhookconfiguration --all
kubectl delete ns nsm-system
```
