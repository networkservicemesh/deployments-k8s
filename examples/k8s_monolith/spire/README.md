## Setup spire for k8s + docker

This example shows how to simply configure spire servers to know each other.
Docker container uses binary spire server.

## Run

1. Setup spire on the k8s cluster

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/k8s_monolith/spire?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a
```

Wait for PODs status ready:
```bash
kubectl wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-agent
```
```bash
kubectl wait -n spire --timeout=1m --for=condition=ready pod -l app=spire-server
```


2. Bootstrap Federation

To enable the SPIRE Servers to fetch the trust bundles from each other they need each other's trust bundle first, because they have to authenticate the SPIFFE identity of the federated server that is trying to access the federation endpoint. Once federation is bootstrapped, the trust bundle updates are fetched through the federation endpoint API using the current trust bundle.

Get and store bundles of the k8s cluster and the docker container:
```bash
bundlek8s=$(kubectl exec spire-server-0 -n spire -- bin/spire-server bundle show -format spiffe)
bundledock=$(docker exec nse-simple-vl3-docker bin/spire-server bundle show -format spiffe)
echo $bundledock | kubectl exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://docker.nsm/cmd-nse-simple-vl3-docker"
echo $bundlek8s | docker exec -i nse-simple-vl3-docker bin/spire-server bundle set -format spiffe -id "spiffe://k8s.nsm"
```

## Cleanup

Cleanup spire resources for k8s cluster

```bash
kubectl delete crd spiffeids.spiffeid.spiffe.io
kubectl delete ns spire
```
