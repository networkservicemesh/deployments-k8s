# Basic examples

Contain basic setup for NSM that includes `nsmgr`, `forwarder-vpp`, `registry-k8s`.
Special env variable is used for this setup to support telemetry.

## Requires

- [spire](../../spire/single_cluster)

## Run

Apply NSM resources for basic tests:

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/observability/nsm_system?ref=a1bc45bfefa413866a097fc41fd7da3b48dd3fcb
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
