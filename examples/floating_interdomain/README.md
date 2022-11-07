# Basic floating interdomain examples

### Floating interdomain

Basic floating interdomain examples includes the next setup:

![NSM floating interdomain Scheme](./floating_interdomain_concept.png "NSM Basic floating interdomain Scheme")

### Interdomain
Interdomain tests can be on two clusters, for thus tests scheme of request will look as:

![NSM  interdomain Scheme](./interdomain_concept.png "NSM Basic floating interdomain Scheme")



## Requires

- [Load balancer](./loadbalancer)
- [Interdomain-DNS](./dns)
- [Interdomain-spire](./spire)

## Includes

- [Kernel to VXLAN to Kernel Connection](./usecases/Kernel2Vxlan2Kernel)
- [Kernel to VXLAN to Kernel Connection via floating registry](./usecases/FloatingKernel2Vxlan2Kernel)
- [Kernel to WIREGUARD to Kernel Connection](./usecases/Kernel2Wireguard2Kernel)
- [Kernel to WIREGUARD to Kernel Connection via floating registry](./usecases/FloatingKernel2Wireguard2Kernel)
- [Floating VL3](./usecases/FloatingVl3)
- [Floating VL3_scale_from_zero](./usecases/FloatingVl3-scale-from-zero)

## Run

**1. Apply deployments for cluster1:**

```bash
export KUBECONFIG=$KUBECONFIG1
```

```bash
kubectl create ns nsm-system
```

Apply NSM resources for basic tests:
```bash
kubectl apply -k ./clusters-configuration/cluster1
```

Wait for nsmgr-proxy-service exposing:
```bash
kubectl get services nsmgr-proxy -n nsm-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

Wait for admission-webhook-k8s:
```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```

**2. Apply deployments for cluster2:**

```bash
export KUBECONFIG=$KUBECONFIG2
```

```bash
kubectl create ns nsm-system
```

Apply NSM resources for basic tests:

```bash
kubectl apply -k ./clusters-configuration/cluster2
```

Wait for nsmgr-proxy-service exposing:
```bash
kubectl get services nsmgr-proxy -n nsm-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

Wait for admission-webhook-k8s:
```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```

**3. Apply deployments for cluster3:**

```bash
export KUBECONFIG=$KUBECONFIG3
```

```bash
kubectl create ns nsm-system
```

Apply NSM resources for basic tests:

```bash
kubectl apply -k ./clusters-configuration/cluster3
```

Wait for nsmgr-proxy-service exposing:
```bash
kubectl get services registry -n nsm-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

## Cleanup

To free resouces follow the next command:

```bash
export KUBECONFIG=$KUBECONFIG1
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl delete mutatingwebhookconfiguration ${WH}
kubectl delete ns nsm-system
```
```bash
export KUBECONFIG=$KUBECONFIG2
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl delete mutatingwebhookconfiguration ${WH}
kubectl delete ns nsm-system
```
```bash
export KUBECONFIG=$KUBECONFIG3 && kubectl delete ns nsm-system
```
