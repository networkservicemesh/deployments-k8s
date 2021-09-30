## Setup spire for three clusters

This example shows how to simply configure three spire servers from different clusters to know each other.

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
kubectl apply -k github.com/networkservicemesh/deployments-k8s/examples/interdomain/spire/cluster1?ref=ff1971140cc0ce3521ecb7a1552ea189939bbd1f
```

Wait for PODs status ready:
```bash
kubectl wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-agent
```
```bash
kubectl wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-server
```

Register spire agents in the spire server:
```bash
kubectl exec -n spire spire-server-0 -- \
/opt/spire/bin/spire-server entry create \
-spiffeID spiffe://nsm.cluster1/ns/spire/sa/spire-agent \
-selector k8s_sat:cluster:nsm.cluster1 \
-selector k8s_sat:agent_ns:spire \
-selector k8s_sat:agent_sa:spire-agent \
-node
```

**Apply spire resources for the second cluster:**
```bash
export KUBECONFIG=$KUBECONFIG2
```

```bash
kubectl apply -k github.com/networkservicemesh/deployments-k8s/examples/interdomain/spire/cluster2?ref=ff1971140cc0ce3521ecb7a1552ea189939bbd1f
```

Wait for PODs status ready:
```bash
kubectl wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-agent
```
```bash
kubectl wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-server
```

Register spire agents in the spire server:
```bash
kubectl exec -n spire spire-server-0 -- \
/opt/spire/bin/spire-server entry create \
-spiffeID spiffe://nsm.cluster2/ns/spire/sa/spire-agent \
-selector k8s_sat:cluster:nsm.cluster2 \
-selector k8s_sat:agent_ns:spire \
-selector k8s_sat:agent_sa:spire-agent \
-node
```

**Apply spire resources for the third cluster:**
```bash
export KUBECONFIG=$KUBECONFIG3
```

```bash
kubectl apply -k github.com/networkservicemesh/deployments-k8s/examples/interdomain/spire/cluster3?ref=ff1971140cc0ce3521ecb7a1552ea189939bbd1f
```

Wait for PODs status ready:
```bash
kubectl wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-agent
```
```bash
kubectl wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-server
```

Register spire agents in the spire server:
```bash
kubectl exec -n spire spire-server-0 -- \
/opt/spire/bin/spire-server entry create \
-spiffeID spiffe://nsm.cluster3/ns/spire/sa/spire-agent \
-selector k8s_sat:cluster:nsm.cluster3 \
-selector k8s_sat:agent_ns:spire \
-selector k8s_sat:agent_sa:spire-agent \
-node
```

3. Bootstrap Federation

To enable the SPIRE Servers to fetch the trust bundles from each other they need each other's trust bundle first, because they have to authenticate the SPIFFE identity of the federated server that is trying to access the federation endpoint. Once federation is bootstrapped, the trust bundle updates are fetched trough the federation endpoint API using the current trust bundle.


Get and store bundles of clusters:
```bash
export KUBECONFIG=$KUBECONFIG1 && bundle1=$(kubectl exec spire-server-0 -n spire -- bin/spire-server bundle show -format spiffe)
export KUBECONFIG=$KUBECONFIG2 && bundle2=$(kubectl exec spire-server-0 -n spire -- bin/spire-server bundle show -format spiffe)
export KUBECONFIG=$KUBECONFIG3 && bundle3=$(kubectl exec spire-server-0 -n spire -- bin/spire-server bundle show -format spiffe)
```

Switch to the first cluster:
```bash
export KUBECONFIG=$KUBECONFIG1
```

Set bundles for the first cluster:

```bash
echo $bundle2 | kubectl exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster2"
echo $bundle3 | kubectl exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster3"
```

Switch to the second cluster:
```bash
export KUBECONFIG=$KUBECONFIG2
```

Set bundles for the second cluster:
```bash
echo $bundle1 | kubectl exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster1"
echo $bundle3 | kubectl exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster3"
```

Switch to the third cluster:
```bash
export KUBECONFIG=$KUBECONFIG3
```

Set bundles for the third cluster:
```bash
echo $bundle1 | kubectl exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster1"
echo $bundle2 | kubectl exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster2"
```


## Cleanup

Cleanup spire resources for all clusters

```bash
export KUBECONFIG=$KUBECONFIG1 && kubectl delete ns spire
export KUBECONFIG=$KUBECONFIG2 && kubectl delete ns spire
export KUBECONFIG=$KUBECONFIG3 && kubectl delete ns spire
```
