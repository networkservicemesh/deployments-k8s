# Test kernel to kernel connection over VLAN Trunking at NSE side


This example shows that NS Clients and NSE on the one node can find each other. 

NS Clients and NSE are using the `kernel` mechanism to connect to its local ovs forwarder.
The NS Client connections are multiplexed over single veth pair interface on the NSE side.

## Requires

Make sure that you have completed steps from [ovs](../../ovs) setup.
There is more consumption of heap memory by NSE pod due to vpp process when host is configured with
hugepage, so in this case NSE pod should be created with memory limit > 2.2 GB.

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/7758662e8a91c411ed8740e9f76c3c921d87d321/examples/use-cases/namespace.yaml)[0])
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

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-kernel?ref=7758662e8a91c411ed8740e9f76c3c921d87d321
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-vlan-vpp?ref=7758662e8a91c411ed8740e9f76c3c921d87d321

patchesStrategicMerge:
- patch-nsc.yaml
- patch-nse.yaml
EOF
```

Create NSC patch:
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
              value: kernel://vlan-vpp-responder/nsm-1
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
              value: 172.16.1.100/30
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
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ${NAMESPACE}
```

Choose one ns client pod and nse pod by labels:
```bash
NSC=$((kubectl get pods -l app=nsc-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{" "}}{{end}}') | cut -d' ' -f1)
TARGET_IP=$(kubectl exec -ti ${NSC} -n ${NAMESPACE} -- ip route show | grep 172.16 | cut -d' ' -f1)
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- ping -c 4 ${TARGET_IP}
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ${NAMESPACE}
```
