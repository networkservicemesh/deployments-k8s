# Spire CSI

This setup deploys SPIRE along with [SPIFFE CSI driver](https://github.com/spiffe/spiffe-csi)

## Run

To apply spire deployments following the next command:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/spire/single_cluster_csi?ref=40aab5b005fd258a8b211a497a05e23da2aa3e42
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
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/40aab5b005fd258a8b211a497a05e23da2aa3e42/examples/spire/single_cluster/clusterspiffeid-template.yaml
```

```bash
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/40aab5b005fd258a8b211a497a05e23da2aa3e42/examples/spire/base/clusterspiffeid-webhook-template.yaml
```

## Cleanup

Delete ns:
```bash
kubectl delete crd clusterspiffeids.spire.spiffe.io
kubectl delete crd clusterfederatedtrustdomains.spire.spiffe.io
kubectl delete validatingwebhookconfiguration.admissionregistration.k8s.io/spire-controller-manager-webhook
kubectl delete ns spire
```
