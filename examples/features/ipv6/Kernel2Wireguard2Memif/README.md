# Test kernel to wireguard to memif

This example shows that NSC and NSE on the different nodes could find and work with each other using IPv6.

NSC is using the `kernel` mechanism to connect to its local forwarder.
NSE is using the `memif` mechanism to connect to its local forwarder.
Forwarders are using the `wireguard` mechanism to connect with each other.

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/af62e7cfab0b31b71c091b500ec6684692c05e97/examples/features/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

Get nodes exclude control-plane:
```bash
NODES=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}'))
```

Create customization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE}

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/client-app?ref=ac7af207eeeb83630b2f296e349f9de352c474af
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-memif?ref=ac7af207eeeb83630b2f296e349f9de352c474af

patchesStrategicMerge:
- patch-client-app.yaml
- patch-nse.yaml
EOF
```

Create a client patch:
```bash
cat > patch-client-app.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: client-app
spec:
  template:
    metadata:
      annotations:
        networkservicemesh.io: kernel://icmp-responder-ip/nsm-1
    spec:
      nodeSelector:
        kubernetes.io/hostname: ${NODES[0]}
EOF
```

Create NSE patch:
```bash
cat > patch-nse.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse-memif
spec:
  template:
    spec:
      containers:
        - name: nse
          env:
            - name: NSM_CIDR_PREFIX
              value: 2001:db8::/116
            - name: NSM_PAYLOAD
              value: IP
            - name: NSM_SERVICE_NAMES
              value: icmp-responder-ip
      nodeSelector:
        kubernetes.io/hostname: ${NODES[1]}
EOF
```

Deploy NSC and NSE:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=client-app -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-memif -n ${NAMESPACE}
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=client-app -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-memif -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- ping -c 4 2001:db8::
```

Ping from NSE to NSC:
```bash
result=$(kubectl exec "${NSE}" -n "${NAMESPACE}" -- vppctl ping 2001:db8::1 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ${NAMESPACE}
```
