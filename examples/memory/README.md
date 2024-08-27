# Memory examples

Memory example contains setup and tear down logic with default NSM infrastructure and memory based registry backend.

## Requires

- [spire](../spire/single_cluster)

## Run

Apply NSM resources for basic tests:

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/memory?ref=44fc808fa9811a37ff58e1cc4ed7e1d90caee8e9
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
