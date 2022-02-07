# Select forwarder by capability example

The example demonstrates how can be declareded forwarder selection in [network service](https://networkservicemesh.io/docs/concepts/architecture/#network-service).

Important points: 
 - [client](./client.yaml) requests `my-networkservice` service.
 - [forwarder](./forwarder.yaml) registers itself with label `my_forwarder_capability: true`
 - [network service](./service.yaml) declaretes network service `my-networkservice` that contains match for label `my_forwarder_capability: true`
 - [network service-endpoint](./nse-patch.yaml) registers as an [endpoint](https://networkservicemesh.io/docs/concepts/architecture/#network-service-endpoint) for service `my-networkservice`

See at example resources in [kustomization.yaml](./kustomization.yaml)

## Requires

Make sure that you have completed steps from [basic](../../basic) setup.

## Run

Create ns `select-forwarder`

```bash
kubectl create ns select-forwarder
```

Apply example resources:

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/select-forwarder?ref=da0228654084085b3659ed6b519f66f44b6796ce
```

Wait for applications ready:

```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n select-forwarder
```

```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n select-forwarder
```

Find nsc, nse pods by labels:
```bash
NSC=$(kubectl get pods -l app=alpine -n select-forwarder --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n select-forwarder --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n select-forwarder -- ping -c 4 169.254.0.0
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n select-forwarder -- ping -c 4 169.254.0.1
```

Verify that NSMgr selected the correct forwarder:
```bash
kubectl logs ${NSC} -c cmd-nsc -n select-forwarder | grep "my-forwarder-vpp"
```

## Cleanup

```bash
kubectl delete ns select-forwarder
```
