# Client requests for postgresql service

This example demonstrates how Postgres-client can get connectivity to Postgres-server deployment via NSM.
Client pod and server deployment located on different nodes.


## Requires

Make sure that you have completed steps from [features](../)

## Run

Create test namespace:
```bash
kubectl create ns ns-webhook
```

Get all available nodes to deploy:
```bash
NODES=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}'))
```

Create client deployment and set `nodeName` to the first node:
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
    networkservicemesh.io: kernel://webhook/nsm-1
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

Add to nse-kernel the nginx container and set `nodeName` it to the second node:
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
            value: "webhook"
          - name: NSM_REGISTER_SERVICE
            value: "false"
          - name: NSM_CIDR_PREFIX
            value: 172.16.1.100/31
      nodeName: ${NODES[1]}
EOF
```

Create kustomization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ns-webhook

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=eb53399861d97d0b47997c43b62e04f58cd9f94d

resources:
- client.yaml
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/eb53399861d97d0b47997c43b62e04f58cd9f94d/examples/features/webhook/netsvc.yaml

patchesStrategicMerge:
- patch-nse.yaml
EOF
```

Deploy client and nginx-nse
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=nse-kernel -n ns-webhook
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nettools -n ns-webhook
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=nettools -n ns-webhook --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-webhook --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Try to connect from client to nginx service:
```bash
kubectl exec ${NSC} -n ns-webhook -- curl 172.16.1.100:80 | grep -o "<title>Welcome to nginx!</title>"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-webhook
```
