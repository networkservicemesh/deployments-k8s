# Test Mutually Aware NSEs

This example demonstrates mutually aware NSEs usage.

Mutually aware NSEs are allowed to have overlapping IP spaces.

Based on Policy Based Routing example.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a/examples/use-cases/namespace.yaml)[0])
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
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-kernel?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a

patchesStrategicMerge:
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
      nodeName: ${NODE}
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
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel-1 -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel-2 -n ${NAMESPACE}
```

Find NSC pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Install `iproute2` on the client:
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- apk update
kubectl exec ${NSC} -n ${NAMESPACE} -- apk add iproute2
```

Check routes:
```bash
result=$(kubectl exec ${NSC} -n ${NAMESPACE} -- ip r get 172.16.1.100 from 172.16.1.101 ipproto tcp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.1.100 from 172.16.1.101 dev nsm-1"
```

```bash
result=$(kubectl exec ${NSC} -n ${NAMESPACE} -- ip r get 172.16.1.100 from 172.16.1.101 ipproto udp dport 5555)
echo ${result}
echo ${result} | grep -E -q "172.16.1.100 from 172.16.1.101 dev nsm-2"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ${NAMESPACE}
```
