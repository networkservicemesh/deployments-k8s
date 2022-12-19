# Spire

This is a Spire setup for the single cluster scenario.

## Run

To apply spire deployments following the next command:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/spire/single_cluster/?ref=7835a9c69ecd678aa5cbb3fe517908e0b76b9684
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
