
## Setup spire for two k8s + docker

By default Spire servers don't trust each other, even though they are configured as a federation.
They need to be manually configured to be able to authenticate other servers.

Docker container in k8s monolith examples uses it's own Spire server.

Here we obtain Spiffe trust bundles for the server in k8s cluster and for server in docker to initiate connection between them.

Once federation is bootstrapped, the trust bundle updates are fetched trough the federation endpoint API using the current trust bundle.

## Run

Apply the ClusterSPIFFEID CR for the cluster:
```bash
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/24245a5d03453802a2403473d46edba47280e74b/examples/k8s_monolith/external_nsc/spiffe_federation/clusterspiffeid-template.yaml
```

Get and store spire/spiffe bundles:
```bash
bundlek8s=$(kubectl exec spire-server-0 -n spire -- bin/spire-server bundle show -format spiffe)
bundledock=$(docker exec nsc-simple-docker bin/spire-server bundle show -format spiffe)
```

Setup bundle federation
```bash
echo $bundledock | kubectl exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://docker.nsm/cmd-nsc-simple-docker"
echo $bundlek8s | docker exec -i nsc-simple-docker bin/spire-server bundle set -format spiffe -id "spiffe://k8s.nsm"
```

## Cleanup

No special cleanup is required.

Follow the general cleanup instructions for Spire to disable Spire Federation.
