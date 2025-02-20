# Memory examples

Memory example contains setup and tear down logic with default NSM infrastructure and memory based registry backend.

## Requires

- [spire](../spire/single_cluster)

## Run

Apply NSM resources for basic tests:

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/memory?ref=c1a6983fcec9479b07c9c367a550ec00a8b11d82
```

Wait for admission-webhook-k8s:

```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```

## Includes

- [Memif to Memif Connection](./Memif2Memif)
- [Kernel to Kernel Connection](./Kernel2Kernel)
- [Kernel to Ethernet to Kernel Connection](./Kernel2Ethernet2Kernel)

## Cleanup

To free resources follow the next commands:

```bash
kubectl delete mutatingwebhookconfiguration nsm-mutating-webhook
kubectl delete ns nsm-system
```
