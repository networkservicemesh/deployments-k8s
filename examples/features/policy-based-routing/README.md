# Policy Based Routing

This example shows policy based routing usage.

NSE is configured by ConfigMap that contains the policy routes.

Based on Kernel2Kernel example.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a/examples/features/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
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

resources:
- client.yaml
- config-file-nse.yaml
bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a

patchesStrategicMerge:
- patch-nse.yaml
EOF
```

Create Client that contains `iproute2`:
```bash
cat > client.yaml <<EOF
---
apiVersion: v1
kind: Pod
metadata:
  name: nettools
  labels:
    app: nettools
  annotations:
    networkservicemesh.io: kernel://icmp-responder/nsm-1
spec:
  containers:
  - name: nettools
    image: travelping/nettools:1.10.1
    imagePullPolicy: IfNotPresent
    stdin: true
    tty: true
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
              value: 172.16.1.100/31
          volumeMounts:
            - mountPath: /etc/policy-based-routing/config.yaml
              subPath: config.yaml
              name: policies-config-volume
      volumes:
        - name: policies-config-volume
          configMap:
            name: policies-config-file
      nodeName: ${NODE}
EOF
```

Deploy NSC and NSE:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nettools -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ${NAMESPACE}
```

Find nsc and nse pods by labels:
```bash
NSC=$(kubectl get pods -l app=nettools -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
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

Check policy based routing:
```bash
result=$(kubectl exec ${NSC} -n ${NAMESPACE} -- ip r get 172.16.3.1 from 172.16.2.201 ipproto tcp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.3.1 from 172.16.2.201 via 172.16.2.200 dev nsm-1 table 1"
```

```bash
result=$(kubectl exec ${NSC} -n ${NAMESPACE} -- ip r get 172.16.3.1 from 172.16.2.201 ipproto tcp sport 5555)
echo ${result}
echo ${result} | grep -E -q "172.16.3.1 from 172.16.2.201 dev nsm-1 table 2"
```

```bash
result=$(kubectl exec ${NSC} -n ${NAMESPACE} -- ip r get 172.16.4.1 ipproto udp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.4.1 dev nsm-1 table 3 src 172.16.1.101"
```

```bash
result=$(kubectl exec ${NSC} -n ${NAMESPACE} -- ip r get 172.16.4.1 ipproto udp dport 6668)
echo ${result}
echo ${result} | grep -E -q "172.16.4.1 dev nsm-1 table 4 src 172.16.1.101"
```

```bash
result=$(kubectl exec ${NSC} -n ${NAMESPACE} -- ip -6 route get 2004::5 from 2004::3 ipproto udp dport 5555)
echo ${result}
echo ${result} | grep -E -q "via 2004::6 dev nsm-1 table 5 src 2004::3"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ${NAMESPACE}
```
