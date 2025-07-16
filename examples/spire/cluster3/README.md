# Spire

This is a part of the Spire setup that installs Spire to the third cluster in a multi-cluster scenarios.

This example assumes [interdomain](../../interdomain/) scenario.
If your cluster setup differs from these scenarios you may need to adjust spire configs (rename trust domains, change URLS, etc.).

## Run

Check that we have config for the cluster:
```bash
[[ ! -z $KUBECONFIG3 ]]
```

Apply spire deployments:
```bash
kubectl --kubeconfig=$KUBECONFIG3 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/spire/cluster3?ref=f91eaf599b454ac73c91acb2e189804797a8b5dd
```

Wait for PODs status ready:
```bash
kubectl --kubeconfig=$KUBECONFIG3 wait -n spire --timeout=3m --for=condition=ready pod -l app=spire-server
```
```bash
kubectl --kubeconfig=$KUBECONFIG3 wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-agent
```

Apply the ClusterSPIFFEID CR for the cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG3 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/f91eaf599b454ac73c91acb2e189804797a8b5dd/examples/spire/cluster3/clusterspiffeid-template.yaml
```

```bash
kubectl --kubeconfig=$KUBECONFIG3 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/f91eaf599b454ac73c91acb2e189804797a8b5dd/examples/spire/base/clusterspiffeid-webhook-template.yaml
```

## Cleanup

Delete ns:
```bash
kubectl --kubeconfig=$KUBECONFIG3 delete crd clusterspiffeids.spire.spiffe.io
kubectl --kubeconfig=$KUBECONFIG3 delete crd clusterfederatedtrustdomains.spire.spiffe.io
kubectl --kubeconfig=$KUBECONFIG3 delete crd clusterstaticentries.spire.spiffe.io
kubectl --kubeconfig=$KUBECONFIG3 delete crd controllermanagerconfigs.spire.spiffe.io
kubectl --kubeconfig=$KUBECONFIG3 delete validatingwebhookconfiguration.admissionregistration.k8s.io/spire-controller-manager-webhook
kubectl --kubeconfig=$KUBECONFIG3 delete ns spire
```
