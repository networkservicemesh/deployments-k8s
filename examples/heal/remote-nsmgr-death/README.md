# Remote NSMgr death

This example shows that NSM keeps working after the remote NSMgr death.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-remote-nsmgr-death
```

Get nodes exclude control-plane:
```bash
NODES=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}'))
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
              value: kernel://remote-nsmgr-death/nsm-1

      nodeName: ${NODES[0]}
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
              value: "remote-nsmgr-death"
            - name: NSM_REGISTER_SERVICE
              value: "false"
      nodeName: ${NODES[1]}
EOF
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/remote-nsmgr-death?ref=562c4f9383ab2a2526008bd7ebace8acf8b18080
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel -n ns-remote-nsmgr-death
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-remote-nsmgr-death
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-kernel -n ns-remote-nsmgr-death --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-remote-nsmgr-death --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-remote-nsmgr-death -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-remote-nsmgr-death -- ping -c 4 172.16.1.101
```

Kill remote NSMgr:

Customization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: nsm-system

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nsmgr?ref=b3b9066d54b23eee85de6a5b1578c7b49065fb89

resources:
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/90929a4302a03a46d22e303c375c488f9336693e/examples/heal/remote-nsmgr-death/netsvc.yaml

patchesStrategicMerge:
- patch-nsmgr.yaml
EOF
```

NSMgr patch:
```bash
cat > patch-nsmgr.yaml <<EOF
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nsmgr
spec:
  updateStrategy:
    type: OnDelete
  template:
    spec:
      containers:
        - name: nsmgr
      nodeName: ${NODES[0]}
EOF
```

Apply changes:
```bash
kubectl apply -k .
```

Start local NSE instead of the remote one:

Customization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ns-remote-nsmgr-death

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=b3b9066d54b23eee85de6a5b1578c7b49065fb89

resources:
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/90929a4302a03a46d22e303c375c488f9336693e/examples/heal/remote-nsmgr-death/netsvc.yaml

patchesStrategicMerge:
- patch-nse.yaml
EOF
```

NSE patch:
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
              value: 172.16.1.102/31
            - name: NSM_SERVICE_NAMES
              value: "remote-nsmgr-death"
            - name: NSM_REGISTER_SERVICE
              value: "false"
      nodeName: ${NODES[0]}
EOF
```

Apply changes:
```bash
kubectl apply -k .
```

Wait for the new NSE to start:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel --field-selector spec.nodeName==${NODES[0]} -n ns-remote-nsmgr-death
```

Find new NSE pod:
```bash
NEW_NSE=$(kubectl get pods -l app=nse-kernel --field-selector spec.nodeName==${NODES[0]} -n ns-remote-nsmgr-death --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to new NSE:
```bash
kubectl exec ${NSC} -n ns-remote-nsmgr-death -- ping -c 4 172.16.1.102
```

Ping from new NSE to NSC:
```bash
kubectl exec ${NEW_NSE} -n ns-remote-nsmgr-death -- ping -c 4 172.16.1.103
```

## Cleanup

Restore NSMgr setup:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/apps/nsmgr?ref=b3b9066d54b23eee85de6a5b1578c7b49065fb89 -n nsm-system
```

Delete ns:
```bash
kubectl delete ns ns-remote-nsmgr-death
```
