# Spire

This is a Spire setup for the single cluster scenario.

## Run

To apply spire deployments following the next command:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/spire/single_cluster/?ref=89a551b8319a3603e108e919be16dce6cdcf3877
```

Wait for PODs status ready:
```bash
kubectl wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-server
```
```bash
kubectl wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-agent
```

## Cleanup

Delete ns:
```bash
kubectl delete crd spiffeids.spiffeid.spiffe.io
kubectl delete ns spire
```
