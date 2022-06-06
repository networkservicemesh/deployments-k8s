## Setup spire for three clusters

This example shows how to simply configure two spire servers from different clusters to know each other.

## Run

Install spire
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k ./cluster1
kubectl --kubeconfig=$KUBECONFIG2 apply -k ./cluster2
```

Setup bundle federation for each cluster
```bash
bundle1=$(kubectl --kubeconfig=$KUBECONFIG1 exec spire-server-0 -n spire -- bin/spire-server bundle show -format spiffe)
bundle2=$(kubectl --kubeconfig=$KUBECONFIG2 exec spire-server-0 -n spire -- bin/spire-server bundle show -format spiffe)

echo $bundle2 | kubectl --kubeconfig=$KUBECONFIG1 exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster2"

echo $bundle1 | kubectl --kubeconfig=$KUBECONFIG2 exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster1"
```

## Cleanup

```bash
kubectl --kubeconfig=$KUBECONFIG1 delete crd spiffeids.spiffeid.spiffe.io
kubectl --kubeconfig=$KUBECONFIG2 delete crd spiffeids.spiffeid.spiffe.io
kubectl --kubeconfig=$KUBECONFIG1 delete -k ./cluster1
kubectl --kubeconfig=$KUBECONFIG2 delete -k ./cluster2
```