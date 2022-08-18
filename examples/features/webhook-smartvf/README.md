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

Get all available nodes to deploy:
```bash
NODES=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}'))
```

Create postgres client deployment, set `nodeName` to the first node and use the interface pool for SmartVF in `sriovToken` annotation label:
```bash
cat > postgres-cl.yaml <<EOF
---
apiVersion: v1
kind: Pod
metadata:
  name: postgres-cl
  annotations:
    # Add in the sriovToken label your own SmartVF interface pool
    networkservicemesh.io: kernel://webhook-smartvf/nsm-1?sriovToken=worker.domain/100G
  labels:
    app: postgres-cl
    "spiffe.io/spiffe-id": "true"
spec:
  containers:
  - name: postgres-cl
    image: postgres
    imagePullPolicy: IfNotPresent
    env:
      - name: POSTGRES_HOST_AUTH_METHOD
        value: trust
  nodeName: ${NODES[0]}
EOF
```

Add to nse-kernel the postgres container, set `nodeName` it to the second node and use the interface pool for SmartVF in `nse` container:
```bash
cat > patch-nse.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse-kernel
spec:
  template:
    spec:
      containers:
        - name: postgres
          image: postgres
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_DB
              value: test
            - name: POSTGRES_USER
              value: admin
            - name: POSTGRES_PASSWORD
              value: admin
        - name: nse
          env:
            - name: NSM_LABELS
              # Add your own serviceDomain
              value: serviceDomain:worker.domain
            - name: NSM_SERVICE_NAMES
              value: "webhook-smartvf"
            - name: NSM_REGISTER_SERVICE
              value: "false"
            - name: NSM_CIDR_PREFIX
              value: 172.16.1.100/31
          resources:
            limits:
              # Add your own SmartVF interface pool
              worker.domain/100G: 1
      nodeName: ${NODES[1]}
EOF
```

Deploy postgres-nsc and postgres-nse
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/webhook-smartvf?ref=562c4f9383ab2a2526008bd7ebace8acf8b18080
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
