# Client requests for postgresql service

This example demonstrates how Postgres-client can get connectivity to Postgres-server deployment via NSM.
Client pod and server deployment located on different nodes.


## Requires

Make sure that you have completed steps from [features](../)

## Run

1. Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a/examples/features/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

3. Get all available nodes to deploy:
```bash
NODES=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}'))
```

4. Create client deployment and set `nodeName` to the first node:
```bash
cat > client.yaml <<EOF
---
apiVersion: v1
kind: Pod
metadata:
  name: nettools
  labels:
    app: nettools
  annotations:
    networkservicemesh.io: kernel://my-nginx-service/nsm-1
spec:
  containers:
  - name: nettools
    image: travelping/nettools:1.10.1
    imagePullPolicy: IfNotPresent
    stdin: true
    tty: true
  nodeName: ${NODE}
EOF
```

5. Add to nse-kernel the nginx container and set `nodeName` it to the second node:
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
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
      - name: nse
        env:
          - name: NSM_SERVICE_NAMES
            value: my-nginx-service
          - name: NSM_CIDR_PREFIX
            value: 172.16.1.100/31
      nodeName: ${NODES[1]}
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
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a

resources:
- client.yaml

patchesStrategicMerge:
- patch-nse.yaml
EOF
```

7. Deploy client and nginx-nse
```bash
kubectl apply -k .
```

8. Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=nse-kernel -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nettools -n ${NAMESPACE}
```

9. Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=nettools -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

10. Try to connect from client to nginx service:
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- curl 172.16.1.100:80 | grep -o "<title>Welcome to nginx!</title>"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ${NAMESPACE}
```
