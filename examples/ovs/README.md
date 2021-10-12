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

```

2. Apply NSM resources for basic tests:

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/ovs?ref=c5da92b2060db54088855f7ef5a89790e8bad979
```

## Cleanup

To free resouces follow the next command:

```bash
kubectl delete mutatingwebhookconfiguration --all
kubectl delete ns nsm-system
```
