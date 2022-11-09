## Setup spire for two clusters

This example shows how to simply configure two spire servers from different clusters to know each other.

## Run

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
