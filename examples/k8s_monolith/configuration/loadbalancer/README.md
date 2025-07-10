# Kubernetes load balancer

Before starting with installation, make sure you meet all the [requirements](https://metallb.universe.tf/#requirements). In particular, you should pay attention to network addon [compatibility](https://metallb.universe.tf/installation/clouds/).

If you’re trying to run MetalLB on a cloud platform, you should also look at the cloud compatibility page and make sure your cloud platform can work with MetalLB (most cannot).

If you want to use metallb, you need to set `CLUSTER_CIDR` env from which addresses for kubernetes services will be allocated.
Please note - IPs from the `CLUSTER_CIDR` must be available to the docker container.\
If you are using `kind` cluster, by default docker containers (kubernetes cluster nodes) are in `172.18.0.0/16` subnet. To be sure, please check `docker network inspect kind`.\
Therefore, for the `CLUSTER_CIDR` you can take for example `172.18.1.0/24`.

## Run

Apply metallb for the cluster:
```bash
if [[ ! -z $CLUSTER_CIDR ]]; then
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
    kubectl wait --for=condition=ready --timeout=5m pod -l app=metallb -n metallb-system
    kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
  - $CLUSTER_CIDR
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

Delete metallb-system namespace from the cluster:

```bash
if [[ ! -z $CLUSTER_CIDR ]]; then
  kubectl delete ns metallb-system
fi
```
