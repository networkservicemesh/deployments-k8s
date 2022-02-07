# Floating interdomain kernel2wireguard2kernel example

This example shows that NSC can reach NSE registered in floating registry.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `wireguard` mechanism to connect with each other.


Important points:
- nsc deploys on cluster1 and requests network service from *cluster3*.
- nse deploys on cluster2 and registers itself  in *cluster3* with IP payload.


## Requires

Make sure that you have completed steps from [interdomain](../../)

## Run

**1. Prepare cluster2**

Switch to *cluster2*:

```bash
export KUBECONFIG=$KUBECONFIG2
```

Create test namespace:
```bash
NAMESPACE1=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/da0228654084085b3659ed6b519f66f44b6796ce/examples/interdomain/usecases/namespace.yaml)[0])
NAMESPACE1=${NAMESPACE1:10}
```

Create kustomization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE1}

resources:
- nse.yaml

EOF
```

Deploy NSE:
```bash
kubectl apply -k .
```

Find NSE pod by labels:
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ${NAMESPACE1} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
[[ ! -z $NSE ]]
```

**2. Prepare cluster1**

Switch to *cluster1*:

```bash
export KUBECONFIG=$KUBECONFIG1
```

Create test namespace:
```bash
NAMESPACE2=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/da0228654084085b3659ed6b519f66f44b6796ce/examples/interdomain/usecases/namespace.yaml)[0])
NAMESPACE2=${NAMESPACE2:10}
```

Create kustomization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE2}

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-kernel?ref=da0228654084085b3659ed6b519f66f44b6796ce

patchesStrategicMerge:
- patch-nsc.yaml
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
              value: kernel://my-networkservice-ip@my.cluster3/nsm-1
EOF
``````

Deploy NSC:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=nsc-kernel -n ${NAMESPACE2}
```


Find NSC pod by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-kernel -n ${NAMESPACE2} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```


**3. Ping from NSC to NSE:**

Switch to *cluster1*:

```bash
export KUBECONFIG=$KUBECONFIG1
```

```bash
kubectl exec ${NSC} -n ${NAMESPACE2} -- ping -c 4 172.16.1.2
```

Switch to *cluster2*:

```bash
export KUBECONFIG=$KUBECONFIG2
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ${NAMESPACE1} -- ping -c 4 172.16.1.3
```

## Cleanup

1. Cleanup resources for *cluster2*:
```bash
export KUBECONFIG=$KUBECONFIG2
```
```bash
kubectl delete ns ${NAMESPACE1}
```

2. Cleanup resources for *cluster1*:
```bash
export KUBECONFIG=$KUBECONFIG1
```
```bash
kubectl delete ns ${NAMESPACE2}
```
