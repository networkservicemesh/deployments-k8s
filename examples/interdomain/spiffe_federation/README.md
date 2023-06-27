## Setup spire for two clusters

By default Spire servers don't trust each other, even though they are configured as a federation.
They need to be manually configured to be able to authenticate other servers.

Here we obtain Spiffe trust bundles for required clusters to initiate connection between Spire servers.

Once federation is bootstrapped, the trust bundle updates are fetched trough the federation endpoint API using the current trust bundle.

## Run

Apply the ClusterSPIFFEID CR for the first cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/c0edc2e01042a7ca9d24b8fcf8a79f45f2349a7a/examples/interdomain/spiffe_federation/cluster1-spiffeid-template.yaml
```

Apply the ClusterSPIFFEID CR for the second cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/c0edc2e01042a7ca9d24b8fcf8a79f45f2349a7a/examples/interdomain/spiffe_federation/cluster2-spiffeid-template.yaml
```

Get and store bundles for clusters:
```bash
bundle1=$(kubectl --kubeconfig=$KUBECONFIG1 exec spire-server-0 -n spire -- bin/spire-server bundle show -format spiffe)
bundle2=$(kubectl --kubeconfig=$KUBECONFIG2 exec spire-server-0 -n spire -- bin/spire-server bundle show -format spiffe)
```

Setup bundle federation for each cluster
```bash
echo $bundle2 | kubectl --kubeconfig=$KUBECONFIG1 exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster2"
echo $bundle1 | kubectl --kubeconfig=$KUBECONFIG2 exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster1"
```

## Cleanup

No special cleanup is required.

Follow the general cleanup instructions for Spire to disable Spire Federation.
