# Spire

This is a Spire setup for the single cluster scenario.

## Run

To apply spire deployments following the next command:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/spire/single_cluster?ref=0364b0a7e87306c0e4d4bf645804f2ffac3a4f9d
```

Wait for PODs status ready:
```bash
kubectl wait -n spire --timeout=4m --for=condition=ready pod -l app=spire-server
```
```bash
kubectl wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-agent
```

Apply the ClusterSPIFFEID CR for the cluster:
```bash
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/0364b0a7e87306c0e4d4bf645804f2ffac3a4f9d/examples/spire/single_cluster/clusterspiffeid-template.yaml
```

```bash
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/0364b0a7e87306c0e4d4bf645804f2ffac3a4f9d/examples/spire/base/clusterspiffeid-webhook-template.yaml
```

## Cleanup

Delete ns:
```bash
kubectl delete crd clusterspiffeids.spire.spiffe.io
kubectl delete crd clusterfederatedtrustdomains.spire.spiffe.io
kubectl delete validatingwebhookconfiguration.admissionregistration.k8s.io/spire-controller-manager-webhook
kubectl delete ns spire
```
