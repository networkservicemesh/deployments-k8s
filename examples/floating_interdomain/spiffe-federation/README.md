## Bootstrap Spiffe Federation

By default Spire servers don't trust each other, even though they are configured as a federation.
They need to be manually configured to be able to authenticate other servers.

Here we obtain Spiffe trust bundles for required clusters to initiate connection between Spire servers.

Once federation is bootstrapped, the trust bundle updates are fetched trough the federation endpoint API using the current trust bundle.

## Run

Get and store bundles for clusters:
```bash
bundle1=$(kubectl --kubeconfig=$KUBECONFIG1 exec spire-server-0 -n spire -- bin/spire-server bundle show -format spiffe)
bundle2=$(kubectl --kubeconfig=$KUBECONFIG2 exec spire-server-0 -n spire -- bin/spire-server bundle show -format spiffe)
bundle3=$(kubectl --kubeconfig=$KUBECONFIG3 exec spire-server-0 -n spire -- bin/spire-server bundle show -format spiffe)
```

Set bundles for the first cluster:
```bash
echo $bundle2 | kubectl --kubeconfig=$KUBECONFIG1 exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster2"
echo $bundle3 | kubectl --kubeconfig=$KUBECONFIG1 exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster3"
```

Set bundles for the second cluster:
```bash
echo $bundle1 | kubectl --kubeconfig=$KUBECONFIG2 exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster1"
echo $bundle3 | kubectl --kubeconfig=$KUBECONFIG2 exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster3"
```

Set bundles for the third cluster:
```bash
echo $bundle1 | kubectl --kubeconfig=$KUBECONFIG3 exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster1"
echo $bundle2 | kubectl --kubeconfig=$KUBECONFIG3 exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster2"
```

## Cleanup

No special cleanup is required.

Follow the general cleanup instructions for Spire to disable Spire Federation.
