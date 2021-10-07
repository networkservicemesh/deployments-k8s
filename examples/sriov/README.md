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
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/sriov?ref=3b620cb8fd028d10ca06ebbcc8ec51c49d339a0d
```

## Cleanup

To free resources follow the next command:
```bash
kubectl delete mutatingwebhookconfiguration --all
kubectl delete ns nsm-system
```
