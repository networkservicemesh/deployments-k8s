# Test automatic scale from zero

This example shows that NSEs can be created on the fly, allowing effective scaling by the node.

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f ../namespace.yaml)[0])
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

Create customization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE}

bases:
- ../../../apps/nse-supplier-k8s
- ../../../apps/nsc-kernel

patchesStrategicMerge:
- patch-nsc.yaml
- patch-supplier.yaml
EOF
```

Register network service:
```bash
kubectl apply -f scale-ns.yaml
```

Deploy NSC and supplier:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-supplier-k8s -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-icmp-responder -n ${NAMESPACE}
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-icmp-responder -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Check connectivity:
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- ping -c 4 169.254.0.0
```

Check connectivity:
```bash
kubectl exec ${NSE} -n ${NAMESPACE} -- ping -c 4 169.254.0.1
```

Remove the client pod:
```bash
kubectl scale -n ${NAMESPACE} deployment nsc-kernel --replicas=0
```

Wait for the NSE pod to be deleted:
```bash
kubectl wait --for=delete --timeout=1m pod -l app=nse-icmp-responder -n ${NAMESPACE}
```

## Cleanup

Delete namespace:
```bash
kubectl delete ns ${NAMESPACE}
```
Delete network service:
```bash
kubectl delete -n nsm-system networkservices.networkservicemesh.io autoscale-icmp-responder
```
