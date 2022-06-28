# Kubernetes load balancer

Before starting with installation, make sure you meet all the [requirements](https://metallb.universe.tf/#requirements). In particular, you should pay attention to network addon [compatibility](https://metallb.universe.tf/installation/clouds/).

If you’re trying to run MetalLB on a cloud platform, you should also look at the cloud compatibility page and make sure your cloud platform can work with MetalLB (most cannot).

There are three supported ways to install MetalLB: using plain Kubernetes manifests, using Kustomize, or using Helm.

## Run

Apply metallb for the cluster:
```bash
if [[ ! -z $CLUSTER_CIDR ]]; then
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
        - $CLUSTER_CIDR
EOF
  kubectl apply -f metallb-config.yaml
  kubectl wait --for=condition=ready --timeout=5m pod -l app=metallb -n metallb-system
fi
```

## Cleanup

Delete metallb-system namespace from the cluster:

```bash
if [[ ! -z $CLUSTER_CIDR ]]; then
  kubectl delete ns metallb-system
fi
```
