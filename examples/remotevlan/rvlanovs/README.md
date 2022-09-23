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
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/remotevlan/rvlanovs?ref=ec0fd5cb8ab9c7b0750b8f536f7166db0a77e9e9
```

Wait forwarder to start:

```bash
kubectl -n nsm-system wait --for=condition=ready --timeout=2m pod -l app=forwarder-ovs
```

## Cleanup

Delete the forwarder:

```bash
kubectl delete -k https://github.com/networkservicemesh/deployments-k8s/examples/remotevlan/rvlanovs?ref=ec0fd5cb8ab9c7b0750b8f536f7166db0a77e9e9
```
