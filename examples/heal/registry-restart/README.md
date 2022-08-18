# Test registry restart

This example shows that NSM keeps working after the Registry restart.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-registry-restart
```

Select node to deploy NSC and NSE:
```bash
NODE=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}')[0])
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
              value: kernel://registry-restart/nsm-1
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
              value: 172.16.1.100/30
            - name: NSM_SERVICE_NAMES
              value: "registry-restart"
            - name: NSM_REGISTER_SERVICE
              value: "false"   
      nodeName: ${NODE}
EOF
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/registry-restart?ref=562c4f9383ab2a2526008bd7ebace8acf8b18080
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel -n ns-registry-restart
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-registry-restart
```

Find nsc and nse pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-kernel -n ns-registry-restart --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-registry-restart --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-registry-restart -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-registry-restart -- ping -c 4 172.16.1.101
```

Find Registry:
```bash
REGISTRY=$(kubectl get pods -l app=registry -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Restart Registry and wait for it to start:
```bash
kubectl delete pod ${REGISTRY} -n nsm-system
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=registry -n nsm-system
```

Create customization file for a new NSC:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ns-registry-restart

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-kernel?ref=b3b9066d54b23eee85de6a5b1578c7b49065fb89

patchesJson6902:
- target:
    group: apps
    version: v1
    kind: Deployment
    name: nsc-kernel
  path: patch-nsc.yaml
EOF
```

Create patch for a new NSC:
```bash
cat > patch-nsc.yaml <<EOF
---
- op: replace
  path: /metadata/name
  value: nsc-kernel-new
- op: replace
  path: /metadata/labels/app
  value: nsc-kernel-new
- op: replace
  path: /spec/selector/matchLabels/app
  value: nsc-kernel-new
- op: replace
  path: /spec/template/metadata/labels/app
  value: nsc-kernel-new
- op: add
  path: /spec/template/spec/containers/0/env/-
  value:
    name: NSM_NETWORK_SERVICES
    value: kernel://registry-restart/nsm-1
EOF
```

Apply:
```bash
kubectl apply -k .
```

Wait for a new NSC to start:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel-new -n ns-registry-restart
```

Find new NSC pod:
```bash
NEW_NSC=$(kubectl get pods -l app=nsc-kernel-new -n ns-registry-restart --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from new NSC to NSE:
```bash
kubectl exec ${NEW_NSC} -n ns-registry-restart -- ping -c 4 172.16.1.102
```

Ping from NSE to new NSC:
```bash
kubectl exec ${NSE} -n ns-registry-restart -- ping -c 4 172.16.1.103
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-registry-restart
```
