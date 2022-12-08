# Spire

This is a part of the Spire setup that installs Spire to the first cluster in a multi-cluster scenarios.

This example assumes [interdomain](../../interdomain/) or [multi-cluster](../../multicluster/) scenario.
If your cluster setup differs from these scenarios you may need to adjust spire configs (rename trust domains, change URLS, etc.).

## Run

Check that we have config for the cluster:
```bash
[[ ! -z $KUBECONFIG1 ]]
```

Apply spire deployments:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/spire/cluster1?ref=158c6ff07d0e3fe4bc8ec4e547be2d16937994a4
```

Wait for PODs status ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-server
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-agent
```

## Cleanup

Delete ns:
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete crd spiffeids.spiffeid.spiffe.io
kubectl --kubeconfig=$KUBECONFIG1 delete ns spire
```
