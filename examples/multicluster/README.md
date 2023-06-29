# Basic floating interdomain examples

### Floating interdomain

Basic floating interdomain examples includes the next setup:

![NSM floating interdomain Scheme](./floating_interdomain_concept.png "NSM Basic floating interdomain Scheme")

### Interdomain
Interdomain tests can be on two clusters, for thus tests scheme of request will look as:

![NSM  interdomain Scheme](./interdomain_concept.png "NSM Basic floating interdomain Scheme")

## Requires

- [Load balancer](./loadbalancer)
- [Interdomain DNS](./dns)
- Interdomain spire
    - [Spire on first cluster](../spire/cluster1)
    - [Spire on second cluster](../spire/cluster2)
    - [Spire on third cluster](../spire/cluster3)
    - [Spiffe Federation](./spiffe_federation)

## Includes

- [Kernel to Ethernet to Kernel Connection](./usecases/interdomain_Kernel2Ethernet2Kernel)
- [Kernel to Ethernet to Kernel Connection via floating registry](./usecases/floating_Kernel2Ethernet2Kernel)
- [Kernel to IP to Kernel Connection](./usecases/interdomain_Kernel2IP2Kernel)
- [Kernel to IP to Kernel Connection via floating registry](./usecases/floating_Kernel2IP2Kernel)
- [DNS](./usecases/interdomain_dns)
- [Floating DNS](./usecases/floating_dns)
- [Floating VL3](./usecases/floating_vl3-basic)
- [Floating VL3_scale_from_zero](./usecases/floating_vl3-scale-from-zero)
- [Floating VL3 DNS](./usecases/floating_vl3-dns)
- [Floating NSE Composition](./usecases/floating_nse_composition)

## Run

**1. Apply deployments for cluster1:**
Apply NSM resources for basic tests:

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/clusters-configuration/cluster1?ref=1abc478c606f5e03937596f1ddd597572c40e5ef
```

Wait for nsmgr-proxy-service exposing:
```bash
kubectl --kubeconfig=$KUBECONFIG1 get services nsmgr-proxy -n nsm-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

Wait for admission-webhook-k8s:
```bash
WH=$(kubectl --kubeconfig=$KUBECONFIG1 get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```

**2. Apply deployments for cluster2:**

Apply NSM resources for basic tests:

```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/clusters-configuration/cluster2?ref=1abc478c606f5e03937596f1ddd597572c40e5ef
```

Wait for nsmgr-proxy-service exposing:
```bash
kubectl --kubeconfig=$KUBECONFIG2 get services nsmgr-proxy -n nsm-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

Wait for admission-webhook-k8s:
```bash
WH=$(kubectl --kubeconfig=$KUBECONFIG2 get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```

**3. Apply deployments for cluster3:**

Apply NSM resources for basic tests:

```bash
kubectl --kubeconfig=$KUBECONFIG3 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster/clusters-configuration/cluster3?ref=1abc478c606f5e03937596f1ddd597572c40e5ef
```

Wait for nsmgr-proxy-service exposing:
```bash
kubectl --kubeconfig=$KUBECONFIG3 get services registry -n nsm-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

## Cleanup

To free resouces follow the next command:

```bash
WH=$(kubectl --kubeconfig=$KUBECONFIG1 get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl --kubeconfig=$KUBECONFIG1 delete mutatingwebhookconfiguration ${WH}
kubectl --kubeconfig=$KUBECONFIG1 delete ns nsm-system
```
```bash
WH=$(kubectl --kubeconfig=$KUBECONFIG2 get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl --kubeconfig=$KUBECONFIG2 delete mutatingwebhookconfiguration ${WH}
kubectl --kubeconfig=$KUBECONFIG2 delete ns nsm-system
```
```bash
kubectl --kubeconfig=$KUBECONFIG3 delete ns nsm-system
```
