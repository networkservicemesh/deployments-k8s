# Test kernel to kernel connection


This example shows that NSC and NSE on the one node can find each other by ipv6 addresses.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.

## Run

Create test namespace:
```bash
kubectl create ns ns-kernel2kernel-ipv6
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

namespace: ns-kernel2kernel-ipv6

resources: 
- client.yaml
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/eb53399861d97d0b47997c43b62e04f58cd9f94d/examples/features/ipv6/Kernel2Kernel_ipv6/netsvc.yaml
bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=eb53399861d97d0b47997c43b62e04f58cd9f94d

patchesStrategicMerge:
- patch-nse.yaml
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
    networkservicemesh.io: kernel://kernel2kernel-ipv6/nsm-1
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
            - name: NSM_SERVICE_NAMES
              value: "kernel2kernel-ipv6"
            - name: NSM_REGISTER_SERVICE
              value: "false"
            - name: NSM_CIDR_PREFIX
              value: 2001:db8::/116
      nodeName: ${NODE}
EOF
```

Deploy NSC and NSE:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-kernel2kernel-ipv6
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-kernel2kernel-ipv6
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=alpine -n ns-kernel2kernel-ipv6 --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-kernel2kernel-ipv6 --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Check connectivity:
```bash
kubectl exec ${NSC} -n ns-kernel2kernel-ipv6 -- ping -c 4 2001:db8::
```

Check connectivity:
```bash
kubectl exec ${NSE} -n ns-kernel2kernel-ipv6 -- ping -c 4 2001:db8::1
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-kernel2kernel-ipv6
```
