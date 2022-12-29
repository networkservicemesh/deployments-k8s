# Spire

This is a part of the Spire setup that installs Spire to the third cluster in a multi-cluster scenarios.

This example assumes [interdomain](../../interdomain/) or [multi-cluster](../../multicluster/) scenario.
If your cluster setup differs from these scenarios you may need to adjust spire configs (rename trust domains, change URLS, etc.).

## Run

Check that we have config for the cluster:
```bash
[[ ! -z $KUBECONFIG3 ]]
```

Apply spire deployments:
```bash
kubectl --kubeconfig=$KUBECONFIG3 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/spire/cluster3?ref=087df8920a84903fb22cf0c2ab8d41423cbb14d4
```

Wait for PODs status ready:
```bash
kubectl --kubeconfig=$KUBECONFIG3 wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-server
```
```bash
kubectl --kubeconfig=$KUBECONFIG3 wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-agent
```

## Cleanup

Delete ns:
```bash
kubectl --kubeconfig=$KUBECONFIG3 delete crd spiffeids.spiffeid.spiffe.io
kubectl --kubeconfig=$KUBECONFIG3 delete ns spire
```
