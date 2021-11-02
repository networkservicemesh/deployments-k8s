# OVS examples

Contain basic setup for NSM that includes `nsmgr`, `forwarder-ovs`, `registry-k8s`, `admission-webhook-k8s`. This setup can be used to check mechanisms combination or some kind of NSM [features](../features).

## Requires

- [spire](../spire)

## Includes

- [Kernel to Kernel Connection](../use-cases/Kernel2Kernel)
- [SmartVF to SmartVF Connection](../use-cases/SmartVF2SmartVF)

## Run

1. Create ns for deployments:
```bash
kubectl create ns nsm-system
```

2. Apply NSM resources for basic tests:

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/ovs?ref=b1c88bba0243278e4bca88d97fe2a66861fde433
```

## Cleanup

To free resouces follow the next command:

```bash
kubectl delete mutatingwebhookconfiguration --all
kubectl delete ns nsm-system
```
