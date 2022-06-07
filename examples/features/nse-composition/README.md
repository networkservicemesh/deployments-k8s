# Test NSE composition

This example demonstrates a more complex Network Service, where we chain three passthrough and one ACL Filtering NS endpoints.
It demonstrates how NSM allows for service composition (chaining).
It involves a combination of kernel and memif mechanisms, as well as VPP enabled endpoints.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/7758662e8a91c411ed8740e9f76c3c921d87d321/examples/features/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

Select node to deploy NSC and NSE:
```bash
NODE=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}')[0])
```

Create customization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: ${NAMESPACE}

resources:
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/7758662e8a91c411ed8740e9f76c3c921d87d321/examples/features/nse-composition/config-file.yaml
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/7758662e8a91c411ed8740e9f76c3c921d87d321/examples/features/nse-composition/passthrough-1.yaml
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/7758662e8a91c411ed8740e9f76c3c921d87d321/examples/features/nse-composition/passthrough-2.yaml
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/7758662e8a91c411ed8740e9f76c3c921d87d321/examples/features/nse-composition/passthrough-3.yaml
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/7758662e8a91c411ed8740e9f76c3c921d87d321/examples/features/nse-composition/nse-composition-ns.yaml
- client.yaml
bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=7758662e8a91c411ed8740e9f76c3c921d87d321
- https://github.com/networkservicemesh/deployments-k8s/examples/features/nse-composition/nse-firewall?ref=7758662e8a91c411ed8740e9f76c3c921d87d321

patchesStrategicMerge:
- patch-nse.yaml

configMapGenerator:
  - name: nginx-config
    files:
      - https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/7758662e8a91c411ed8740e9f76c3c921d87d321/examples/features/nse-composition/nginx.conf
EOF
```

Create Client:
```bash
cat > client.yaml <<EOF
---
apiVersion: v1
kind: Pod
metadata:
  name: alpine
  labels:
    app: alpine    
  annotations:
    networkservicemesh.io: kernel://nse-composition/nsm-1
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
            - name: NSM_SERVICE_NAMES
              value: "nse-composition"
            - name: NSM_REGISTER_SERVICE
              value: "false"
            - name: NSM_LABELS
              value: "app:gateway"
        - name: nginx
          image: nginx
          ports:
          - containerPort: 80
          - containerPort: 8080
          volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx/nginx.conf
              subPath: nginx.conf
              readOnly: true
          imagePullPolicy: IfNotPresent
      nodeName: ${NODE}
      volumes:
        - name: nginx-config
          configMap:
            name: nginx-config
EOF
```

Deploy NSC and NSE:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ${NAMESPACE}
```

Find nsc and nse pods by labels:
```bash
NSC=$(kubectl get pods -l app=alpine -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- ping -c 4 172.16.1.100
```

Check TCP Port 8080 on NSE is accessible to NSC
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- wget -O /dev/null --timeout 5 "172.16.1.100:8080"
```

Check TCP Port 80 on NSE is inaccessible to NSC
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- wget -O /dev/null --timeout 5 "172.16.1.100:80"
if [ 0 -eq $? ]; then
  echo "error: port :80 is available" >&2
  false
else
  echo "success: port :80 is unavailable"
fi
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ${NAMESPACE} -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ${NAMESPACE}
```
