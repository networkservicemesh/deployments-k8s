# Pod Security Standard (PSS) examples

Contain basic setup for NSM that includes `nsm-admission-webhook` `nsmgr`, `forwarder-vpp`, `registry-k8s` and [NSM CSI driver](https://github.com/networkservicemesh/cmd-csi-driver).
CSI driver allows us to avoid using `hostPath` volumes in workloads.

Based on the [PSS profile](https://kubernetes.io/docs/concepts/security/pod-security-standards/), the admission-webhook adds the required security settings to the NSM sidecar containers.

**_Please note_** that the webhook only knows about the profile from **_the namespace labels_**.

## Requires

- [spire_csi](../spire/single_cluster_csi)

## Run

Apply NSM resources:

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/pss/nsm-system?ref=v1.15.0-rc.1
```

Wait for admission-webhook-k8s:

```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```

## Includes

- [Nginx service](use-cases/nginx)

## Cleanup

Due to CSI driver limitations, we first need to remove pods that contain a volume mounted by the driver:
```bash
kubectl delete ds/forwarder-vpp -n nsm-system
```

To free resources follow the next commands:
```bash
kubectl delete mutatingwebhookconfiguration nsm-mutating-webhook
kubectl delete ns nsm-system
```
