# Test SR-IOV kernel connection

This example shows that NSC and NSE can work with each other over the SR-IOV kernel connection.

## Requires

Make sure that you have completed steps from [sriov](../../sriov) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-sriov-kernel2noop
```

Create customization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ns-sriov-kernel2noop

resources: 
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/946696acae3156e3e72bdb42cdda5147725fd0a2/examples/use-cases/SriovKernel2Noop/netsvc.yaml

bases:
<<<<<<< HEAD
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-kernel?ref=9570de2ce5e79a76bbe2db5f02f819ab869032d1
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=9570de2ce5e79a76bbe2db5f02f819ab869032d1
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-kernel-ponger?ref=9570de2ce5e79a76bbe2db5f02f819ab869032d1
=======
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-kernel?ref=946696acae3156e3e72bdb42cdda5147725fd0a2
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=946696acae3156e3e72bdb42cdda5147725fd0a2
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-kernel-ponger?ref=946696acae3156e3e72bdb42cdda5147725fd0a2
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
  name: nsc-kernel
spec:
  template:
    spec:
      containers:
        - name: nsc
          env:
            - name: NSM_NETWORK_SERVICES
              value: kernel://sriov-kernel2noop/nsm-1?sriovToken=worker.domain/10G
          resources:
            limits:
              worker.domain/10G: 1
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
            - name: NSM_LABELS
              value: serviceDomain:worker.domain
            - name: NSM_CIDR_PREFIX
              value: 172.16.1.100/31
            - name: NSM_SERVICE_NAMES
              value: "sriov-kernel2noop"
            - name: NSM_REGISTER_SERVICE
              value: "false"
          resources:
            limits:
              master.domain/10G: 1
EOF
```

Deploy NSC and NSE:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl -n ns-sriov-kernel2noop wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel
```
```bash
kubectl -n ns-sriov-kernel2noop wait --for=condition=ready --timeout=1m pod -l app=nse-kernel
```
```bash
kubectl -n ns-sriov-kernel2noop wait --for=condition=ready --timeout=1m pod -l app=ponger
```

Get NSC pod:
```bash
NSC=$(kubectl -n ns-sriov-kernel2noop get pods -l app=nsc-kernel --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl -n ns-sriov-kernel2noop exec ${NSC} -- ping -c 4 172.16.1.100
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-sriov-kernel2noop
```
