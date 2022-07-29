## Setup spire for three clusters

This example shows how to simply configure two spire servers from different clusters to know each other.

## Run

1. Make sure that you have three KUBECONFIG files.

Check `KUBECONFIG1` env:
```bash
[[ ! -z $KUBECONFIG1 ]]
```

Check `KUBECONFIG2` env:
```bash
[[ ! -z $KUBECONFIG2 ]]
```

Check `KUBECONFIG3` env:
```bash
[[ ! -z $KUBECONFIG3 ]]
```


2. Setup spire


**Apply spire resources for the first cluster:**
```bash
export KUBECONFIG=$KUBECONFIG1
```

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/spire/cluster1?ref=bdbc426a0e1665e385cb3e59ca222cd52d156dc4
```

Wait for PODs status ready:
```bash
kubectl wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-agent
```
```bash
kubectl wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-server
```

**Apply spire resources for the second cluster:**
```bash
export KUBECONFIG=$KUBECONFIG2
```

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/spire/cluster2?ref=bdbc426a0e1665e385cb3e59ca222cd52d156dc4
```

Wait for PODs status ready:
```bash
kubectl wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-agent
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k ./cluster1
kubectl --kubeconfig=$KUBECONFIG2 apply -k ./cluster2
```

Wait for spire ready
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-server
kubectl --kubeconfig=$KUBECONFIG2 wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-server
```

Fetch bundles
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

```bash
kubectl --kubeconfig=$KUBECONFIG1 delete crd spiffeids.spiffeid.spiffe.io
kubectl --kubeconfig=$KUBECONFIG2 delete crd spiffeids.spiffeid.spiffe.io
kubectl --kubeconfig=$KUBECONFIG1 delete ns spire
kubectl --kubeconfig=$KUBECONFIG2 delete ns spire
```