# NSM Remote Vlan OVS Forwarder

Contains setup for `forwarder-ovs` and device configuration file for remote vlan mechanism.

## Requires

Make sure that you have completed steps from [remotevlan](../../remotevlan) setup.

## Includes

- [Kernel2RVlanInternal](../../use-cases/Kernel2RVlanInternal)
- [Kernel2RVlanBreakout](../../use-cases/Kernel2RVlanBreakout)
- [Kernel2RVlanMultiNS](../../use-cases/Kernel2RVlanMultiNS)

## Run

Deploy the forwarder:

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/remotevlan/rvlanovs?ref=cd27b0f27e760b30cd4a3d53c92897c0dfc6deef
```

Wait forwarder to start:

```bash
kubectl -n nsm-system wait --for=condition=ready --timeout=2m pod -l app=forwarder-ovs
```

## Cleanup

Delete the forwarder:

```bash
kubectl delete -k https://github.com/networkservicemesh/deployments-k8s/examples/remotevlan/rvlanovs?ref=cd27b0f27e760b30cd4a3d53c92897c0dfc6deef
```
