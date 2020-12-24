# Test local connection

This example shows that nsc and nse on the different nodes could find each other.

## Run

Create test namespace

```bash
NAMESPACE=($(kubectl create -f namespace.yaml)[0])
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

Select first node to deploy nsc
```bash
NODE1=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}')[0])
```

Select second node to deploy nsc
```bash
NODE2=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}')[1])
```

Create customization file
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE}

bases:
- ../../apps/kernel-nsc
- ../../apps/kernel-nse

patchesStrategicMerge:
- patch-nsc.yaml
- patch-nse.yaml
EOF
```

Create nsc patch to assign to concreate NODE
```bash
cat > patch-nsc.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nsc
spec:
  template:
    spec:
      nodeSelector: 
        kubernetes.io/hostname: ${NODE1}
EOF
```
Create nse patch to assign to concreate NODE
```bash
cat > patch-nse.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse
spec:
  template:
    spec:
      nodeSelector: 
        kubernetes.io/hostname: ${NODE2}
EOF
```

Deploy nsc and nse:

```bash
kubectl apply -k .
```

Wait for applications ready:
```bash 
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse -n ${NAMESPACE}
```

Check connection result:
```bash
kubectl logs -l app=nsc -n ${NAMESPACE} | grep "All client init operations are done."

```

## Cleanup

Delete ns
```bash
kubectl delete ns ${NAMESPACE}
```
