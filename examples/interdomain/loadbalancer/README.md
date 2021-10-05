# Kubernetes load balancer

Before starting with installation, make sure you meet all the [requirements](https://metallb.universe.tf/#requirements). In particular, you should pay attention to network addon [compatibility](https://metallb.universe.tf/installation/clouds/).

If you’re trying to run MetalLB on a cloud platform, you should also look at the cloud compatibility page and make sure your cloud platform can work with MetalLB (most cannot).

There are three supported ways to install MetalLB: using plain Kubernetes manifests, using Kustomize, or using Helm.

## Run

Switch to the first cluster:

```bash
export KUBECONFIG=$KUBECONFIG1
```

Apply metallb for the first cluster:
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/namespace.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)" 
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/metallb.yaml
```

Create metallb config to setup addresses pool:
```bash
cat > metallb-config.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - $CLUSTER_CIDR1
EOF
```

Apply the configmap:
```bash
kubectl apply -f metallb-config.yaml
```

Wait for deployment ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=metallb -n metallb-system
```

Switch to the second cluster:
```bash
export KUBECONFIG=$KUBECONFIG2
```

Apply metallb for the second cluster:
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/namespace.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)" 
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/metallb.yaml
```
Create metallb config to setup addresses pool:
```bash
cat > metallb-config.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - $CLUSTER_CIDR2
EOF
```

Apply the configmap:

```bash
kubectl apply -f metallb-config.yaml
```

Wait for deployment ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=metallb -n metallb-system
```


Switch to the third cluster:
```bash
export KUBECONFIG=$KUBECONFIG3
```

Apply metallb for the third cluster:
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/namespace.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)" 
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/metallb.yaml
```

Create metallb config to setup addresses pool:
```bash
cat > metallb-config.yaml <<EOF
---
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - $CLUSTER_CIDR3
EOF
```

Apply the configmap:

```bash
kubectl apply -f metallb-config.yaml
```

Wait for deployment ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=metallb -n metallb-system
```

## Cleanup


```bash
export KUBECONFIG=$KUBECONFIG1 && kubectl delete ns metallb-system 
```
```bash
export KUBECONFIG=$KUBECONFIG2 && kubectl delete ns metallb-system 
```
```bash
export KUBECONFIG=$KUBECONFIG3 && kubectl delete ns metallb-system 
```
