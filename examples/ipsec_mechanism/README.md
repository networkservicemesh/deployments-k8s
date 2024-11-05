# IPSec remote mechanism examples

Contain a setup for NSM that includes `nsmgr`, `forwarder-vpp`, `registry-k8s`. This setup can be used to check mechanisms combination.\
\
Unlike the [basic setup](../basic), which uses `Wireguard` as the default IP remote mechanism, we prioritize `IPSec` here.

## Requires

- [spire](../spire/single_cluster/)

## Run

Apply NSM resources for basic tests:

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/ipsec_mechanism?ref=07c6e6c4a4d5e890a32a711d54012a8020d05d19
```

Wait for admission-webhook-k8s:

```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```

## Includes

- [Kernel to IP to Kernel Connection](../use-cases/Kernel2IP2Kernel)
- [Memif to IP to Memif Connection](../use-cases/Memif2IP2Memif)
- [Kernel to IP to Memif Connection](../use-cases/Kernel2IP2Memif)
- [Memif to IP to Kernel Connection](../use-cases/Memif2IP2Kernel)
- [vL3-basic](../use-cases/vl3-basic)

## Cleanup

To free resources follow the next commands:

```bash
kubectl delete mutatingwebhookconfiguration nsm-mutating-webhook
kubectl delete ns nsm-system
```
