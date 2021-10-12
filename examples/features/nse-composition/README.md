# Test NSE composition

This example demonstrates a more complex Network Service, where we chain three passthrough and one ACL Filtering NS endpoints.
It demonstrates how NSM allows for service composition (chaining).
It involves a combination of kernel and memif mechanisms, as well as VPP enabled endpoints.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/992468fdd07c2fa1ef5a25235839848296cdc247/examples/features/namespace.yaml)[0])
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
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/992468fdd07c2fa1ef5a25235839848296cdc247/examples/features/nse-composition/config-file.yaml
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/992468fdd07c2fa1ef5a25235839848296cdc247/examples/features/nse-composition/passthrough-1.yaml
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/992468fdd07c2fa1ef5a25235839848296cdc247/examples/features/nse-composition/passthrough-2.yaml
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/992468fdd07c2fa1ef5a25235839848296cdc247/examples/features/nse-composition/passthrough-3.yaml
bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-kernel?ref=992468fdd07c2fa1ef5a25235839848296cdc247
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=992468fdd07c2fa1ef5a25235839848296cdc247
- https://github.com/networkservicemesh/deployments-k8s/examples/features/nse-composition/nse-firewall?ref=992468fdd07c2fa1ef5a25235839848296cdc247

patchesStrategicMerge:
- patch-nsc.yaml
- patch-nse.yaml
EOF
```

Create NSC patch:
```bash
cat > patch-nsc.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nsc-kernel
spec:
  template:
    spec:
      containers:
        - name: nsc
          env:
            - name: NSM_NETWORK_SERVICES
              value: kernel://nse-composition/nsm-1
      nodeSelector:
        kubernetes.io/hostname: ${NODE}
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
          image: networkservicemesh/nginx
          imagePullPolicy: IfNotPresent
      nodeSelector:
        kubernetes.io/hostname: ${NODE}
EOF
```

Deploy Network Service
```bash
kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/992468fdd07c2fa1ef5a25235839848296cdc247/examples/features/nse-composition/nse-composition-ns.yaml
```

Deploy NSC and NSE:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ${NAMESPACE}
```

Find nsc and nse pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
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
