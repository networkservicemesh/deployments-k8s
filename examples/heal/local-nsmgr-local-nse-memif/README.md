# Local NSMgr + Local NSE restart

This example shows that NSM keeps working after the local NSMgr + local NSE restart.

NSC and NSE are using the `memif` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-local-nsmgr-local-nse-memif
```

Get nodes exclude control-plane:
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
  name: nsc-memif
spec:
  template:
    spec:
      containers:
        - name: nsc
          env:
            - name: NSM_NETWORK_SERVICES
              value: memif://local-nsmgr-local-nse-memif/nsm-1

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
  name: nse-memif
spec:
  template:
    spec:
      containers:
        - name: nse
          env:
            - name: NSM_CIDR_PREFIX
              value: 172.16.1.100/31
            - name: NSM_SERVICE_NAMES
              value: "local-nsmgr-local-nse-memif"
            - name: NSM_REGISTER_SERVICE
              value: "false"
      nodeName: ${NODE}
EOF
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/local-nsmgr-local-nse-memif?ref=eb53399861d97d0b47997c43b62e04f58cd9f94d
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-memif -n ns-local-nsmgr-local-nse-memif
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-memif -n ns-local-nsmgr-local-nse-memif
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-memif -n ns-local-nsmgr-local-nse-memif --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-memif -n ns-local-nsmgr-local-nse-memif --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
result=$(kubectl exec "${NSC}" -n "ns-local-nsmgr-local-nse-memif" -- vppctl ping 172.16.1.100 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

Ping from NSE to NSC:
```bash
result=$(kubectl exec "${NSE}" -n "ns-local-nsmgr-local-nse-memif" -- vppctl ping 172.16.1.101 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

Delete the previous NSE:
```bash
kubectl delete deployment nse-memif -n ns-local-nsmgr-local-nse-memif
kubectl wait --for=delete --timeout=1m pod ${NSE} -n ns-local-nsmgr-local-nse-memif
```

Create a new NSE patch:
```bash
cat > patch-nse.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse-memif
spec:
  template:
    metadata:
      labels:
        version: new
    spec:
      containers:
        - name: nse
          env:
            - name: NSM_CIDR_PREFIX
              value: 172.16.1.102/31
            - name: NSM_SERVICE_NAMES
              value: "local-nsmgr-local-nse-memif"
            - name: NSM_REGISTER_SERVICE
              value: "false"
      nodeName: ${NODE}
EOF
```

Find local NSMgr pod:
```bash
NSMGR=$(kubectl get pods -l app=nsmgr --field-selector spec.nodeName==${NODE} -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Restart local NSMgr and NSE:
```bash
kubectl delete pod ${NSMGR} -n nsm-system
```
```bash
kubectl apply -k .
```

Waiting for new ones:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsmgr --field-selector spec.nodeName==${NODE} -n nsm-system
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-memif -l version=new -n ns-local-nsmgr-local-nse-memif
```

Find new NSE pod:
```bash
NEW_NSE=$(kubectl get pods -l app=nse-memif -l version=new -n ns-local-nsmgr-local-nse-memif --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
result=$(kubectl exec "${NSC}" -n "ns-local-nsmgr-local-nse-memif" -- vppctl ping 172.16.1.102 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

Ping from NSE to NSC:
```bash
result=$(kubectl exec "${NEW_NSE}" -n "ns-local-nsmgr-local-nse-memif" -- vppctl ping 172.16.1.103 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-local-nsmgr-local-nse-memif
```
