# Test local Forwarder death

This example shows that NSM keeps working after the local Forwarder death.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/05197ded333d78d1c2073f4152ab3e5f57a3d858/examples/heal/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

Register namespace in `spire` server:
```bash
kubectl exec -n spire spire-server-0 -- \
/opt/spire/bin/spire-server entry create \
-spiffeID spiffe://example.org/ns/${NAMESPACE}/sa/default \
-parentID spiffe://example.org/ns/spire/sa/spire-agent \
-selector k8s:ns:${NAMESPACE} \
-selector k8s:sa:default
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

bases:
- github.com/networkservicemesh/deployments-k8s/apps/nsc-kernel?ref=05197ded333d78d1c2073f4152ab3e5f57a3d858
- github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=05197ded333d78d1c2073f4152ab3e5f57a3d858

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
            - name: NSM_REQUEST_TIMEOUT
              value: 45s
            - name: NSM_NETWORK_SERVICES
              value: kernel://icmp-responder/nsm-1
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
              value: 172.16.1.100/30
      nodeSelector:
        kubernetes.io/hostname: ${NODE}
EOF
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

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ${NAMESPACE} -- ping -c 4 172.16.1.101
```

Find local Forwarder:
```bash
FORWARDER=$(kubectl get pods -l app=forwarder-vpp --field-selector spec.nodeName==${NODE} -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Remove local Forwarder and wait for a new one to start:
```bash
kubectl delete pod -n nsm-system ${FORWARDER}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=forwarder-vpp --field-selector spec.nodeName==${NODE} -n nsm-system
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- ping -c 4 172.16.1.102
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ${NAMESPACE} -- ping -c 4 172.16.1.103
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ${NAMESPACE}
```