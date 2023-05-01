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
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/spire/cluster1?ref=b9684123f38192bd5b50448aa6f49a902870dc9e
```

Wait for PODs status ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-server
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-agent
```

Apply the ClusterSPIFFEID CR for the cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/b9684123f38192bd5b50448aa6f49a902870dc9e/examples/spire/cluster1/clusterspiffeid-template.yaml
```

## Cleanup

Delete ns:
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete crd clusterspiffeids.spire.spiffe.io
kubectl --kubeconfig=$KUBECONFIG1 delete crd clusterfederatedtrustdomains.spire.spiffe.io
kubectl --kubeconfig=$KUBECONFIG1 delete validatingwebhookconfiguration.admissionregistration.k8s.io/spire-controller-manager-webhook
kubectl --kubeconfig=$KUBECONFIG1 delete ns spire
```
