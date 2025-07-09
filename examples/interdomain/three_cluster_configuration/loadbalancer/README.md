# Kubernetes load balancer

Before starting with installation, make sure you meet all the [requirements](https://metallb.universe.tf/#requirements). In particular, you should pay attention to network addon [compatibility](https://metallb.universe.tf/installation/clouds/).

If you’re trying to run MetalLB on a cloud platform, you should also look at the cloud compatibility page and make sure your cloud platform can work with MetalLB (most cannot).

There are three supported ways to install MetalLB: using plain Kubernetes manifests, using Kustomize, or using Helm.

## Run

Switch to the first cluster:

Apply metallb for the first cluster:
```bash
if [[ ! -z $CLUSTER1_CIDR ]]; then
    kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
    kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
    kubectl --kubeconfig=$KUBECONFIG1 apply -f - <<EOF
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
    kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=5m pod -l app=metallb -n metallb-system
fi
```

Apply metallb for the second cluster:
```bash
if [[ ! -z $CLUSTER2_CIDR ]]; then
    kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
    kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
    kubectl --kubeconfig=$KUBECONFIG2 apply -f - <<EOF
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
    kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=5m pod -l app=metallb -n metallb-system
fi
```

Apply metallb for the third cluster:
```bash
if [[ ! -z $CLUSTER3_CIDR ]]; then
    kubectl --kubeconfig=$KUBECONFIG3 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
    kubectl --kubeconfig=$KUBECONFIG3 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
    kubectl --kubeconfig=$KUBECONFIG3 apply -f - <<EOF
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
    kubectl --kubeconfig=$KUBECONFIG3 wait --for=condition=ready --timeout=5m pod -l app=metallb -n metallb-system
fi
```

## Cleanup

Delete metallb-system namespace from all clusters:

```bash
if [[ ! -z $CLUSTER1_CIDR ]]; then
  kubectl --kubeconfig=$KUBECONFIG1 delete ns metallb-system  
fi
```

```bash
if [[ ! -z $CLUSTER2_CIDR ]]; then
  kubectl --kubeconfig=$KUBECONFIG2 delete ns metallb-system  
fi
```

```bash
if [[ ! -z $CLUSTER3_CIDR ]]; then
  kubectl --kubeconfig=$KUBECONFIG3 delete ns metallb-system  
fi
```
