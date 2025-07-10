# Kubernetes load balancer

Before starting with installation, make sure you meet all the [requirements](https://metallb.universe.tf/#requirements). In particular, you should pay attention to network addon [compatibility](https://metallb.universe.tf/installation/clouds/).

If you’re trying to run MetalLB on a cloud platform, you should also look at the cloud compatibility page and make sure your cloud platform can work with MetalLB (most cannot).

There are three supported ways to install MetalLB: using plain Kubernetes manifests, using Kustomize, or using Helm.

## Run

Apply metallb for the first cluster:
```bash
if [[ ! -z $CLUSTER1_CIDR ]]; then
    kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
    kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=5m pod -l app=metallb -n metallb-system
    kubectl --kubeconfig=$KUBECONFIG1 apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
  - $CLUSTER1_CIDR
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
EOF
fi
```

Apply metallb for the second cluster:
```bash
if [[ ! -z $CLUSTER2_CIDR ]]; then
    kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
    kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=5m pod -l app=metallb -n metallb-system
    kubectl --kubeconfig=$KUBECONFIG2 apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
  - $CLUSTER2_CIDR
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
EOF
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
