# Test kernel to kernel connection


This example shows that NSC and NSE on the one node can find each other. 

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/17c1f2fd2682aad88724a6685cd25d0da6940af2/examples/use-cases/namespace.yaml)[0])
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
- nse-1.yaml
- nse-2.yaml
- config-file-nse-1.yaml
- config-file-nse-2.yaml
bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-kernel?ref=17c1f2fd2682aad88724a6685cd25d0da6940af2

patchesStrategicMerge:
- patch-nse-1.yaml
- patch-nse-2.yaml
- patch-nsc.yaml
EOF
```

Create Client:
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
              value: kernel://icmp-responder-1/nsm-1?color=red,kernel://icmp-responder-2/nsm-2?color=red
            - name: NSM_AWARENESS_GROUPS
              value: "[kernel://icmp-responder-1/nsm-1?color=red,kernel://icmp-responder-2/nsm-2?color=red]"
      nodeSelector:
        kubernetes.io/hostname: ${NODE}
EOF
```

Create NSE-1 patch:
```bash
cat > patch-nse-1.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse-kernel-1
spec:
  template:
    spec:
      containers:
        - name: nse
          env:
            - name: NSM_CIDR_PREFIX
              value: 172.16.1.100/31
            - name: NSM_SERVICE_NAMES
              value: icmp-responder-1
          volumeMounts:
            - mountPath: /etc/policy-based-routing/config.yaml
              subPath: config.yaml
              name: policies-config-volume-1
      volumes:
        - name: policies-config-volume-1
          configMap:
            name: policies-config-file-1
      nodeSelector:
        kubernetes.io/hostname: ${NODE}
EOF
```

Create NSE-2 patch:
```bash
cat > patch-nse-2.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse-kernel-2
spec:
  template:
    spec:
      containers:
        - name: nse
          env:
            - name: NSM_CIDR_PREFIX
              value: 172.16.1.100/31
            - name: NSM_SERVICE_NAMES
              value: icmp-responder-2
          volumeMounts:
            - mountPath: /etc/policy-based-routing/config.yaml
              subPath: config.yaml
              name: policies-config-volume-2
      volumes:
        - name: policies-config-volume-2
          configMap:
            name: policies-config-file-2
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
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ${NAMESPACE}
```

Find nsc and nse pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Install `iproute2` on the client:
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- apk update
kubectl exec ${NSC} -n ${NAMESPACE} -- apk add iproute2
```

```bash
result=$(kubectl exec ${NSC} -n ${NAMESPACE} -- ip r get 172.16.1.100 from 172.16.1.101 ipproto tcp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.1.100 from 172.16.1.101 dev nsm-1 table 1"
```

```bash
result=$(kubectl exec ${NSC} -n ${NAMESPACE} -- ip r get 172.16.1.100 from 172.16.1.101 ipproto tcp dport 5555)
echo ${result}
echo ${result} | grep -E -q "172.16.1.100 from 172.16.1.101 dev nsm-1 table 1"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ${NAMESPACE}
```
