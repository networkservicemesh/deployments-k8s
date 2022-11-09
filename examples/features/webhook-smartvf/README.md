# Client requests for postgresql service over SmartVF

This example demonstrates how Postgres-client can get connectivity to Postgres-server deployment via NSM over SmartVF interfaces.
Client pod and server deployment located on different nodes. The nodes must support SmartVF interface pool as resources.


## Requires

Make sure that you have completed steps from [ovs](../../ovs) setup

## Run

Create test namespace:
```bash
kubectl create ns ns-webhook
```

Note: Admission webhook is required and should be started at this moment.
```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```

Deploy postgres-nsc and postgres-nse
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/webhook-smartvf?ref=11270dce0c3935d3ccd62ca81a387d13b3829f8b
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=nse-kernel -n ns-webhook-smartvf
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod postgres-cl -n ns-webhook-smartvf
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=postgres-cl -n ns-webhook-smartvf --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-webhook-smartvf --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Try to connect from postgres-nsc to database from postgresql service:
```bash
kubectl exec ${NSC} -n ns-webhook-smartvf -c postgres-cl -- sh -c 'PGPASSWORD=admin psql -h 172.16.1.100 -p 5432 -U admin test'
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-webhook-smartvf
```
