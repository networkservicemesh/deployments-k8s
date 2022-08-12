# Test kernel to kernel connection with annotated namespace

This example shows that NSM annotations applied to namespace will be applied to the pods within this namespace.  

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.


## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test NAMESPACE with annotation:
```bash
NAMESPACE=($(kubectl create -f ./examples/features/annotated-namespace/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

Select node to deploy clients:
```bash
NODE=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}')[0])
```

Create Client patch:
```bash
cat > client1.yaml <<EOF
---
apiVersion: v1
kind: Pod
metadata:
  name: alpine
  namespace: ${NAMESPACE}
  labels:
    app: alpine    
spec:
  containers:
  - name: alpine
    image: alpine:3.15.0
    imagePullPolicy: IfNotPresent
    stdin: true
    tty: true
  nodeName: ${NODE}
EOF
```

Create customization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: default

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=3d1dcfe1de90681213c7f0006f25279bb4699966

patchesStrategicMerge:
- patch-nse.yaml
EOF
```

Create NSE patch:
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
        - name: nse
          env:
            - name: NSM_CIDR_PREFIX
              value: 172.16.1.100/31
      nodeName: ${NODE}
EOF
```

Deploy NSC and NSE:
```bash
kubectl apply -k
kubectl apply -f client1.yaml
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ${NAMESPACE}
```
 
Find nsc and nse pods by labels:

```bash
NSE=$(kubectl get pods -l app=nse-kernel --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

```bash
NSC=$(kubectl get pods -l app=alpine -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Check that on the client NSM annotation was applied:
```bash
kubectl log pod ${NSC} -c cmd-nsc-init
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -- ping -c 4 172.16.1.101
```


## Cleanup

Delete ns:
```bash
kubectl delete ns ${NAMESPACE}
```
