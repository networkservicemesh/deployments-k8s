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
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/remotevlan/rvlanvpp?ref=cf8131d6a008caef28a2310c5aa582e8ab6dad63
```

Wait forwarder to start:

```bash
kubectl -n nsm-system wait --for=condition=ready --timeout=2m pod -l app=forwarder-vpp
```

## Cleanup

Delete the forwarder:

```bash
kubectl delete -k https://github.com/networkservicemesh/deployments-k8s/examples/remotevlan/rvlanvpp?ref=cf8131d6a008caef28a2310c5aa582e8ab6dad63
```
