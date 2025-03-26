# Spire CSI

This setup deploys SPIRE along with [SPIFFE CSI driver](https://github.com/spiffe/spiffe-csi)

## Run

To apply spire deployments following the next command:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/spire/single_cluster_csi?ref=aaa8aa3a2474e6455e42ef0e512ba19cf2f9b712
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
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/aaa8aa3a2474e6455e42ef0e512ba19cf2f9b712/examples/spire/single_cluster/clusterspiffeid-template.yaml
```

```bash
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/aaa8aa3a2474e6455e42ef0e512ba19cf2f9b712/examples/spire/base/clusterspiffeid-webhook-template.yaml
```

## Cleanup

Delete ns:
```bash
kubectl delete crd clusterspiffeids.spire.spiffe.io
kubectl delete crd clusterfederatedtrustdomains.spire.spiffe.io
kubectl delete validatingwebhookconfiguration.admissionregistration.k8s.io/spire-controller-manager-webhook
kubectl delete ns spire
```
