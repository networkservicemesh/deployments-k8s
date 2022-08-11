# Test memif to kernel connection

This example shows that NSC and NSE on the one node can find each other.

NSC is using the `memif` mechanism to connect to its local forwarder.
NSE is using the `kernel` mechanism to connect to its local forwarder.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-memif2kernel
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

namespace: ns-memif2kernel

resources: 
- https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/Memif2Kernel?ref=946696acae3156e3e72bdb42cdda5147725fd0a2

bases:
<<<<<<< HEAD
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-memif?ref=9570de2ce5e79a76bbe2db5f02f819ab869032d1
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=9570de2ce5e79a76bbe2db5f02f819ab869032d1
=======
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-memif?ref=946696acae3156e3e72bdb42cdda5147725fd0a2
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=946696acae3156e3e72bdb42cdda5147725fd0a2
>>>>>>> 865832b6f4 (set new refs for basic suite examples)

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
  name: nsc-memif
spec:
  template:
    spec:
      containers:
        - name: nsc
          env:
            - name: NSM_NETWORK_SERVICES
              value: memif://memif2kernel/nsm-1
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
            - name: NSM_SERVICE_NAMES
              value: "memif2kernel"
            - name: NSM_REGISTER_SERVICE
              value: "false"
      nodeName: ${NODE}
EOF
```

Deploy NSC and NSE:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-memif -n ns-memif2kernel
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-memif2kernel
```

Find nsc and nse pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-memif -n ns-memif2kernel --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-memif2kernel --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
result=$(kubectl exec "${NSC}" -n "ns-memif2kernel" -- vppctl ping 172.16.1.100 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ns-memif2kernel -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-memif2kernel
```
