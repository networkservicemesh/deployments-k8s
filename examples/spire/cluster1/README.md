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
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/spire/cluster1?ref=6ce44e18801866d9f24f9a8dc209302fe7dd27a2
```

Wait for PODs status ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait -n spire --timeout=3m --for=condition=ready pod -l app=spire-server
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-agent
```

Apply the ClusterSPIFFEID CR for the cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/6ce44e18801866d9f24f9a8dc209302fe7dd27a2/examples/spire/cluster1/clusterspiffeid-template.yaml
```

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/6ce44e18801866d9f24f9a8dc209302fe7dd27a2/examples/spire/base/clusterspiffeid-webhook-template.yaml
```

## Cleanup

Delete ns:
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete crd clusterspiffeids.spire.spiffe.io
kubectl --kubeconfig=$KUBECONFIG1 delete crd clusterfederatedtrustdomains.spire.spiffe.io
kubectl --kubeconfig=$KUBECONFIG1 delete validatingwebhookconfiguration.admissionregistration.k8s.io/spire-controller-manager-webhook
kubectl --kubeconfig=$KUBECONFIG1 delete ns spire
```
