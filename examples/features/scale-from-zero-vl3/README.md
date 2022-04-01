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
kubectl create ns ns-vl3
```

3. Create patch for NSCs:
```bash
cat > patch-nsc.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nsc-kernel
spec:
  replicas: 2
  template:
    spec:
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
      nodeName: $NODE1
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

namespace: ns-vl3

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/vl3-ipam?ref=d3a0d485c43c998dfa365f8693911509afaff911
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-supplier-k8s?ref=d3a0d485c43c998dfa365f8693911509afaff911
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-kernel?ref=d3a0d485c43c998dfa365f8693911509afaff911

patchesStrategicMerge:
- patch-nsc.yaml
- patch-supplier.yaml

configMapGenerator:
  - name: supplier-pod-template-configmap
    files:
      - ./pod-template.yaml
EOF
```

6. Register network service:
```bash
kubectl apply -f ./autoscale-netsvc.yaml
```

7. Deploy NSC and supplier:
```bash
kubectl apply -k .
```

8. Wait for applications ready:
```bash
kubectl wait -n ns-vl3 --for=condition=ready --timeout=1m pod -l app=nse-supplier-k8s
```
```bash
kubectl wait -n ns-vl3 --for=condition=ready --timeout=1m pod -l app=nsc-kernel
```
```bash
kubectl wait -n ns-vl3 --for=condition=ready --timeout=1m pod -l app=nse-vl3-vpp
```

3. Find all nscs:

```bash
nscs=$(kubectl  get pods -l app=nsc-kernel -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}" -n ns-vl3) 
[[ ! -z $nscs ]]
```

4. Ping each client by each client:

```bash
for nsc in $nscs 
do
    ipAddr=$(kubectl exec -n ns-vl3 $nsc -- ifconfig nsm-1)
    ipAddr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    for pinger in $nscs
    do
        echo $pinger pings $ipAddr
        kubectl exec $pinger -n ns-vl3 -- ping -c4 $ipAddr
    done
done
```

## Cleanup

Delete namespace:
```bash
kubectl delete ns ns-vl3
```
Delete network service:
```bash
kubectl delete -n nsm-system networkservices.networkservicemesh.io autoscale-icmp-responder
```
