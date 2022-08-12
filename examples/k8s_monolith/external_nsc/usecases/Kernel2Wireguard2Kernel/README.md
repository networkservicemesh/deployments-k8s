# Test kernel to wireguard to kernel connection

Docker-NSC and NSE are using the `kernel` local mechanism.
`Wireguard` is used as remote mechanism.

## Requires

Make sure that you have completed steps from [external NSC](../../)

## Run

Create test namespace:
```bash
kubectl create ns ns-kernel2wireguard2kernel-monolith-nsc
```

Create kustomization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ns-kernel2wireguard2kernel-monolith-nsc

resources:
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/eb53399861d97d0b47997c43b62e04f58cd9f94d/examples/k8s_monolith/external_nsc/usecases/Kernel2Wireguard2Kernel/netsvc.yaml

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=b3b9066d54b23eee85de6a5b1578c7b49065fb89

patchesStrategicMerge:
- patch-nse.yaml
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
            - name: NSM_PAYLOAD
              value: IP
            - name: NSM_SERVICE_NAMES
              value: "kernel2wireguard2kernel-monolith-nsc"
            - name: NSM_REGISTER_SERVICE
              value: "false"
EOF
```

Deploy NSE:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-kernel2wireguard2kernel-monolith-nsc
```

Find NSE pod by label:
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-kernel2wireguard2kernel-monolith-nsc --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from docker-NSC to NSE:
```bash
docker exec nsc-simple-docker ping -c4 172.16.1.100
```

Ping from NSE to docker-NSC:
```bash
kubectl exec ${NSE} -n ns-kernel2wireguard2kernel-monolith-nsc -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:

```bash
kubectl delete ns ns-kernel2wireguard2kernel-monolith-nsc
```
