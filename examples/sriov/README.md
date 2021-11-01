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

2. Apply NSM resources for SR-IOV tests:
```bash
if [[ "${CALICO}" == on ]]; then # calico
  kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/sriov/calico?ref=6b88da39e40e64d665add469616315a9c289ecdb
else
  kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/sriov/base?ref=6b88da39e40e64d665add469616315a9c289ecdb
fi
```

## Cleanup

To free resources follow the next command:
```bash
kubectl delete mutatingwebhookconfiguration --all
kubectl delete ns nsm-system
```
