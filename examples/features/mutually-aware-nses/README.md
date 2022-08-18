# Test Mutually Aware NSEs

This example demonstrates mutually aware NSEs usage.

Mutually aware NSEs are allowed to have overlapping IP spaces.

Based on Policy Based Routing example.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-mutually-aware-nses
```

Select node to deploy NSC and NSE:
```bash
NODE=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}')[0])
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
              value: kernel://mutually-aware-nses-1/nsm-1?color=red,kernel://mutually-aware-nses-2/nsm-2?color=red
            - name: NSM_AWARENESS_GROUPS
              value: "[kernel://mutually-aware-nses-1/nsm-1?color=red,kernel://mutually-aware-nses-2/nsm-2?color=red]"
      nodeName: ${NODE}
EOF
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/mutually-aware-nses?ref=562c4f9383ab2a2526008bd7ebace8acf8b18080

```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel -n ns-mutually-aware-nses
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel-1 -n ns-mutually-aware-nses
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel-2 -n ns-mutually-aware-nses
```

Find NSC pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-kernel -n ns-mutually-aware-nses --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Install `iproute2` on the client:
```bash
kubectl exec ${NSC} -n ns-mutually-aware-nses -- apk update
kubectl exec ${NSC} -n ns-mutually-aware-nses -- apk add iproute2
```

Check routes:
```bash
result=$(kubectl exec ${NSC} -n ns-mutually-aware-nses -- ip r get 172.16.1.100 from 172.16.1.101 ipproto tcp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.1.100 from 172.16.1.101 dev nsm-1"
```

```bash
result=$(kubectl exec ${NSC} -n ns-mutually-aware-nses -- ip r get 172.16.1.100 from 172.16.1.101 ipproto udp dport 5555)
echo ${result}
echo ${result} | grep -E -q "172.16.1.100 from 172.16.1.101 dev nsm-2"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-mutually-aware-nses
```
