# Spire

This is a part of the Spire setup that installs Spire to the second cluster in a multi-cluster scenarios.

This example assumes [interdomain](../../interdomain/) scenario.
If your cluster setup differs from these scenarios you may need to adjust spire configs (rename trust domains, change URLS, etc.).

## Run

Check that we have config for the cluster:
```bash
[[ ! -z $KUBECONFIG2 ]]
```

Apply spire deployments:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/spire/cluster2?ref=3336f6af36f88b0de452951bdfd4579d8d2ce692
```

Wait for PODs status ready:
```bash
kubectl --kubeconfig=$KUBECONFIG2 wait -n spire --timeout=3m --for=condition=ready pod -l app=spire-server
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-agent
```

Apply the ClusterSPIFFEID CR for the cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/3336f6af36f88b0de452951bdfd4579d8d2ce692/examples/spire/cluster2/clusterspiffeid-template.yaml
```

```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/3336f6af36f88b0de452951bdfd4579d8d2ce692/examples/spire/base/clusterspiffeid-webhook-template.yaml
```

## Cleanup

Delete ns:
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete crd clusterspiffeids.spire.spiffe.io
kubectl --kubeconfig=$KUBECONFIG2 delete crd clusterfederatedtrustdomains.spire.spiffe.io
kubectl --kubeconfig=$KUBECONFIG2 delete crd clusterstaticentries.spire.spiffe.io
kubectl --kubeconfig=$KUBECONFIG2 delete crd controllermanagerconfigs.spire.spiffe.io
kubectl --kubeconfig=$KUBECONFIG2 delete validatingwebhookconfiguration.admissionregistration.k8s.io/spire-controller-manager-webhook
kubectl --kubeconfig=$KUBECONFIG2 delete ns spire
```
