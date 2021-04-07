# Alpine requests for postgresql service

This example demonstrates how alpine can get connectivity to Postgres deployment via NSM.
Alpine pod and Postgres deployment located on different nodes.


## Requires

Make sure that you have completed steps from [features](../)

## Run

1. Create test namespace:
```bash
NAMESPACE=($(kubectl create -f ../../use-cases/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

2. Register namespace in `spire` server:
```bash
kubectl exec -n spire spire-server-0 -- \
/opt/spire/bin/spire-server entry create \
-spiffeID spiffe://example.org/ns/${NAMESPACE}/sa/default \
-parentID spiffe://example.org/ns/spire/sa/spire-agent \
-selector k8s:ns:${NAMESPACE} \
-selector k8s:sa:default
```

3. Get all available nodes to deploy:
```bash
NODES=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}'))
```

4. Create alpine deployment and set `nodeSelector` to the first node:
```bash
cat > alpine.yaml <<EOF
---
apiVersion: v1
kind: Pod
metadata:
  name: alpine
  annotations:
    networkservicemesh.io: kernel://my-postgres-service/nsm-1
  labels:
    app: alpine
spec:
  containers:
  - name: alpine
    image: alpine
    stdin: true
    tty: true
  nodeSelector:
    kubernetes.io/hostname: ${NODES[0]}
EOF
```

5. Add to nse-kernel the postgres container and set `nodeSelector` it to the second node:
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
            - name: NSE_SERVICE_NAME
              value: my-postgres-service
            - name: NSE_CIDR_PREFIX
              value: 172.16.1.100/31
      nodeSelector:
        kubernetes.io/hostname: ${NODES[1]}
EOF
```

6. Create kustomization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE}

bases:
- ../../../apps/nse-kernel

resources:
- alpine.yaml

patchesStrategicMerge:
- patch-nse.yaml
EOF
```

7. Deploy alpine and postgres-nse
```bash
kubectl apply -k .
```

8. Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod alpine -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=nse-kernel -n ${NAMESPACE}
```

9. Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=alpine -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

10. Install to alpine psql:
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- apk update 
```
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- apk add postgresql
```

11. Try to connect from alpine to database from postgresql service:
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -c alpine -- sh -c 'PGPASSWORD=admin psql -h 172.16.1.100 -p 5432 -U admin test'
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ${NAMESPACE}
```