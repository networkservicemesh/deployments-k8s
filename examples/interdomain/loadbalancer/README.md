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
if [[ ! -z $CLUSTER1_CIDR ]]; then
  kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/namespace.yaml
  kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)" 
  kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/metallb.yaml
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
        - $CLUSTER1_CIDR
EOF
  kubectl apply -f metallb-config.yaml
  kubectl wait --for=condition=ready --timeout=5m pod -l app=metallb -n metallb-system
fi
```

Switch to the second cluster:
```bash
export KUBECONFIG=$KUBECONFIG2
```

Apply metallb for the second cluster:
```bash
if [[ ! -z $CLUSTER2_CIDR ]]; then
  kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/namespace.yaml
  kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)" 
  kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/metallb.yaml
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
        - $CLUSTER2_CIDR
EOF
  kubectl apply -f metallb-config.yaml
  kubectl wait --for=condition=ready --timeout=5m pod -l app=metallb -n metallb-system
fi
```

Switch to the third cluster:
```bash
export KUBECONFIG=$KUBECONFIG3
```

Apply metallb for the second cluster:
```bash
if [[ ! -z $CLUSTER3_CIDR ]]; then
  kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/namespace.yaml
  kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)" 
  kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/metallb.yaml
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
        - $CLUSTER3_CIDR
EOF
  kubectl apply -f metallb-config.yaml
  kubectl wait --for=condition=ready --timeout=5m pod -l app=metallb -n metallb-system
fi
```

## Cleanup

Delete metallb-system namespace from all clusters:

```bash
export KUBECONFIG=$KUBECONFIG1 
if [[ ! -z $CLUSTER1_CIDR ]]; then
  kubectl delete ns metallb-system  
fi
```

```bash
export KUBECONFIG=$KUBECONFIG2
if [[ ! -z $CLUSTER2_CIDR ]]; then
  kubectl delete ns metallb-system  
fi
```

```bash
export KUBECONFIG=$KUBECONFIG3
if [[ ! -z $CLUSTER3_CIDR ]]; then
  kubectl delete ns metallb-system  
fi
```
