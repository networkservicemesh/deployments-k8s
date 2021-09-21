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
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain?ref=050a5817cb8104b907e2c241a7af38c08d3102d1
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
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain?ref=050a5817cb8104b907e2c241a7af38c08d3102d1
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
kubectl apply -k github.com/networkservicemesh/deployments-k8s/apps/registry-k8s?ref=050a5817cb8104b907e2c241a7af38c08d3102d1
```

## Cleanup

To free resouces follow the next command:

```bash
export KUBECONFIG=$KUBECONFIG1 && kubectl delete ns nsm-system
```
```bash
export KUBECONFIG=$KUBECONFIG2 && kubectl delete ns nsm-system
```
```bash
export KUBECONFIG=$KUBECONFIG3 && kubectl delete ns nsm-system
```
