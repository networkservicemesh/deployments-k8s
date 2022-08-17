# Local Forwarder + Remote Forwarder restart

This example shows that NSM keeps working after the local Forwarder + remote Forwarder restarts.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-local-forwarder-remote-forwarder
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
              value: kernel://local-forwarder-remote-forwarder/nsm-1

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
              value: "local-forwarder-remote-forwarder"
            - name: NSM_REGISTER_SERVICE
              value: "false"   
      nodeName: ${NODES[1]}
EOF
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/local-forwarder-remote-forwarder?ref=eb53399861d97d0b47997c43b62e04f58cd9f94d
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel -n ns-local-forwarder-remote-forwarder
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-local-forwarder-remote-forwarder
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-kernel -n ns-local-forwarder-remote-forwarder --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-local-forwarder-remote-forwarder --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-local-forwarder-remote-forwarder -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-local-forwarder-remote-forwarder -- ping -c 4 172.16.1.101
```

Find local Forwarder:
```bash
FORWARDER1=$(kubectl get pods -l app=forwarder-vpp --field-selector spec.nodeName==${NODES[0]} -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Find remote Forwarder:
```bash
FORWARDER2=$(kubectl get pods -l app=forwarder-vpp --field-selector spec.nodeName==${NODES[1]} -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Restart local and remote Forwarders:
```bash
kubectl delete pod ${FORWARDER1} -n nsm-system
```
```bash
kubectl delete pod ${FORWARDER2} -n nsm-system 
```

Waiting for new ones:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=forwarder-vpp --field-selector spec.nodeName==${NODES[0]} -n nsm-system
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=forwarder-vpp --field-selector spec.nodeName==${NODES[1]} -n nsm-system
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ns-local-forwarder-remote-forwarder -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-local-forwarder-remote-forwarder -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-local-forwarder-remote-forwarder
```
