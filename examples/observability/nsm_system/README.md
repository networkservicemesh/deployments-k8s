# Basic examples

Contain basic setup for NSM that includes `nsmgr`, `forwarder-vpp`, `registry-k8s`.
Special env variable is used for this setup to support telemetry.

## Requires

- [spire](../../spire/single_cluster)

## Run

Apply NSM resources for basic tests:

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/observability/nsm_system?ref=ee2c69744427e12a5d2d8b0cb7e4547b23c1f428
```

Wait for admission-webhook-k8s:

```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```

## Cleanup

To free resources follow the next commands:

```bash
kubectl delete mutatingwebhookconfiguration nsm-mutating-webhook
kubectl delete ns nsm-system
```
