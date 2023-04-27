# NSM Remote Vlan VPP Forwarder

Contains setup for `forwarder-vpp` and a config map that creates the device selector file in forwarder pod for remote vlan mechanism.

## Requires

Make sure that you have completed steps from [remotevlan](../../remotevlan) setup.

## Includes

- [Kernel2RVlanInternal](../../use-cases/Kernel2RVlanInternal)
- [Kernel2RVlanBreakout](../../use-cases/Kernel2RVlanBreakout)
- [Kernel2RVlanMultiNS](../../use-cases/Kernel2RVlanMultiNS)

## Run

Deploy the forwarder:

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/remotevlan/rvlanvpp?ref=795d14f9128c07ea3c3e768f311f31e61e2365db
```

Wait forwarder to start:

```bash
kubectl -n nsm-system wait --for=condition=ready --timeout=2m pod -l app=forwarder-vpp
```

## Cleanup

Delete the forwarder:

```bash
kubectl delete -k https://github.com/networkservicemesh/deployments-k8s/examples/remotevlan/rvlanvpp?ref=795d14f9128c07ea3c3e768f311f31e61e2365db
```
