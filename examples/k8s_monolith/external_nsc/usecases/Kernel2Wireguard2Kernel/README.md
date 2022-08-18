# Test kernel to wireguard to kernel connection

Docker-NSC and NSE are using the `kernel` local mechanism.
`Wireguard` is used as remote mechanism.

## Requires

Make sure that you have completed steps from [external NSC](../../)

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/0be25be1f7f56369dd1604aff97fb6f6ea38d26b/examples/k8s_monolith/external_nsc/usecases/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

Create kustomization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE}

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=0be25be1f7f56369dd1604aff97fb6f6ea38d26b

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
              value: icmp-responder-ip
EOF
```

Deploy NSE:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ${NAMESPACE}
```

Find NSE pod by label:
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from docker-NSC to NSE:
```bash
docker exec nsc-simple-docker ping -c4 172.16.1.100
```

Ping from NSE to docker-NSC:
```bash
kubectl exec ${NSE} -n ${NAMESPACE} -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:

```bash
kubectl delete ns ${NAMESPACE}
```
