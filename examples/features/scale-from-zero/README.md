# Test automatic scale from zero

This example shows that NSEs can be created on the fly on NSC requests.
This allows effective scaling for endpoints.
The requested endpoint will be automatically spawned on the same node as NSC (see step 12),
allowing the best performance for connectivity.

Here we are using an endpoint that automatically shuts down
when it has no active connection for specified time.
We are using very short timeout for the purpose of the test: 15 seconds.

We are only using one client in this test,
so removing it (see step 13) will cause the NSE to shut down.

Supplier watches for endpoints it created
and clears endpoints that finished their work,
thus saving cluster resources (see step 14).

## Run

1. Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/da0228654084085b3659ed6b519f66f44b6796ce/examples/features/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

2. Select nodes to deploy NSC and supplier:
```bash
NODES=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints }}{{ .metadata.name }} {{end}}{{end}}'))
NSC_NODE=${NODES[0]}
SUPPLIER_NODE=${NODES[1]}
if [ "$SUPPLIER_NODE" == "" ]; then SUPPLIER_NODE=$NSC_NODE; echo "Only 1 node found, testing that pod is created on the same node is useless"; fi
```

3. Create patch for NSC:
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
      nodeName: $NSC_NODE
      containers:
        - name: nsc
          env:
            - name: NSM_NETWORK_SERVICES
              value: kernel://autoscale-icmp-responder/nsm-1
            - name: NSM_REQUEST_TIMEOUT
              value: 30s
EOF
```

4. Create patch for supplier:
```bash
cat > patch-supplier.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse-supplier-k8s
spec:
  template:
    spec:
      nodeName: $SUPPLIER_NODE
      containers:
        - name: nse-supplier
          env:
            - name: NSM_SERVICE_NAME
              value: autoscale-icmp-responder
            - name: NSM_LABELS
              value: app:icmp-responder-supplier
            - name: NSM_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: NSM_POD_DESCRIPTION_FILE
              value: /run/supplier/pod-template.yaml
          volumeMounts:
            - name: pod-file
              mountPath: /run/supplier
              readOnly: true
      volumes:
        - name: pod-file
          configMap:
            name: supplier-pod-template-configmap
EOF
```

5. Create customization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: $NAMESPACE

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-supplier-k8s?ref=da0228654084085b3659ed6b519f66f44b6796ce
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-kernel?ref=da0228654084085b3659ed6b519f66f44b6796ce

patchesStrategicMerge:
- patch-nsc.yaml
- patch-supplier.yaml

configMapGenerator:
  - name: supplier-pod-template-configmap
    files:
      - https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/da0228654084085b3659ed6b519f66f44b6796ce/examples/features/scale-from-zero/pod-template.yaml
EOF
```

6. Register network service:
```bash
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/da0228654084085b3659ed6b519f66f44b6796ce/examples/features/scale-from-zero/autoscale-netsvc.yaml
```

7. Deploy NSC and supplier:
```bash
kubectl apply -k .
```

8. Wait for applications ready:
```bash
kubectl wait -n $NAMESPACE --for=condition=ready --timeout=1m pod -l app=nse-supplier-k8s
```
```bash
kubectl wait -n $NAMESPACE --for=condition=ready --timeout=1m pod -l app=nsc-kernel
```
```bash
kubectl wait -n $NAMESPACE --for=condition=ready --timeout=1m pod -l app=nse-icmp-responder
```

9. Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pod -n $NAMESPACE --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' -l app=nsc-kernel)
NSE=$(kubectl get pod -n $NAMESPACE --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' -l app=nse-icmp-responder)
```

10. Check connectivity:
```bash
kubectl exec $NSC -n $NAMESPACE -- ping -c 4 169.254.0.0
```
```bash
kubectl exec $NSE -n $NAMESPACE -- ping -c 4 169.254.0.1
```

11. Check that the NSE spawned on the same node as NSC:
```bash
NSE_NODE=$(kubectl get pod -n $NAMESPACE --template '{{range .items}}{{.spec.nodeName}}{{"\n"}}{{end}}' -l app=nse-icmp-responder)
```
```bash
if [ $NSC_NODE == $NSE_NODE ]; then echo "OK"; else echo "different nodes"; false; fi
```

12. Remove NSC:
```bash
kubectl scale -n $NAMESPACE deployment nsc-kernel --replicas=0
```

13. Wait for the NSE pod to be deleted:
```bash
kubectl wait -n $NAMESPACE --for=delete --timeout=1m pod -l app=nse-icmp-responder
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
