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

Install Linkerd CLI:
```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```
Verify Linkerd CLI is installed:
```bash
linkerd version
```
If not, export linkerd path to $PATH:


Install Linkerd onto cluster:
```bash
linkerd check --pre
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -
linkerd check
```


1. Create test namespace:
```bash
kubectl create ns ns-nsm-linkerd
```

2. Select nodes to deploy NSC and supplier:
```bash
NODES=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints }}{{ .metadata.name }} {{end}}{{end}}'))
NSC_NODE=${NODES[0]}
SUPPLIER_NODE=${NODES[1]}
if [ "$SUPPLIER_NODE" == "" ]; then SUPPLIER_NODE=$NSC_NODE; echo "Only 1 node found, testing that pod is created on the same node is useless"; fi
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

namespace: ns-nsm-linkerd

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-supplier-k8s?ref=5278bf09564d36b701e8434d9f1d4be912e6c266
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-kernel?ref=5278bf09564d36b701e8434d9f1d4be912e6c266

patchesStrategicMerge:
- patch-nsc.yaml
- patch-supplier.yaml

configMapGenerator:
  - name: supplier-pod-template-configmap
    files:
      - https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/5278bf09564d36b701e8434d9f1d4be912e6c266/examples/features/scale-from-zero/pod-template.yaml
EOF
```

6. Register network service:
```bash
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/5278bf09564d36b701e8434d9f1d4be912e6c266/examples/features/scale-from-zero/autoscale-netsvc.yaml
```

7. Deploy NSC and supplier:
```bash
kubectl apply -k .
```

8. Wait for applications ready:
```bash
kubectl wait -n ns-nsm-linkerd --for=condition=ready --timeout=1m pod -l app=nse-supplier-k8s
kubectl wait -n ns-nsm-linkerd --for=condition=ready --timeout=1m pod -l app=nsc-kernel
kubectl wait -n ns-nsm-linkerd --for=condition=ready --timeout=1m pod -l app=nse-icmp-responder
```

9. Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pod -n ns-nsm-linkerd --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' -l app=nsc-kernel)
NSE=$(kubectl get pod -n ns-nsm-linkerd --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' -l app=nse-icmp-responder)
```

Check connectivity:
```bash
kubectl exec $NSC -n ns-nsm-linkerd -- ping -c 4 169.254.0.0
```
```bash
kubectl exec $NSE -n ns-nsm-linkerd -- ping -c 4 169.254.0.1
```
Remove NSC:
```bash
kubectl scale -n ns-nsm-linkerd deployment nsc-kernel --replicas=0
```

Wait for the NSE pod to be deleted:
```bash
kubectl wait -n ns-nsm-linkerd --for=delete --timeout=1m pod -l app=nse-icmp-responder
```
Scale NSC up:
```bash
kubectl scale -n ns-nsm-linkerd deployment nsc-kernel --replicas=1
```

Inject Linkerd into NSC:
```bash
kubectl get -n ns-nsm-linkerd deploy nsc-kernel -o yaml | linkerd inject - | kubectl apply -f -
```
```bash
NSC=$(kubectl get pod -n ns-nsm-linkerd --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' -l app=nsc-kernel)
```

10. Check connectivity:
```bash
kubectl exec $NSC -n ns-nsm-linkerd -c nsc -- ping -c 4 169.254.0.0
```
```bash
kubectl exec $NSE -n ns-nsm-linkerd -- ping -c 4 169.254.0.1
```
Remove NSC:
```bash
kubectl scale -n ns-nsm-linkerd deployment nsc-kernel --replicas=0
```

Wait for the NSE pod to be deleted:
```bash
kubectl wait -n ns-nsm-linkerd --for=delete --timeout=1m pod -l app=nse-icmp-responder
```
 




## Cleanup

Uninject linkerd proxy from deployments:
```bash
kubectl get -n ns-nsm-linkerd deploy nsc-kernel -o yaml | linkerd uninject - | kubectl apply -f -
```
Delete namespace:
```bash
kubectl delete ns ns-nsm-linkerd
```
Delete network service:
```bash
kubectl delete -n nsm-system networkservices.networkservicemesh.io autoscale-icmp-responder
```
Remove Linkerd control plane from cluster:
```bash
linkerd uninstall | kubectl delete -f -
```