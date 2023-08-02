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

- [nse death](./heal/floating-nse-death)
- [Local and remote nsmgr death](./heal/floating-nsmgr-death)
- [Local and remote forwarder death](./heal/floating-forwarder-death)
- [Local and remote nsmgr-proxy death](./heal/floating-proxy-nsmgr-death)
- [Local and remote nsmgr-proxy death](./heal/floating-nsm-system-death)
- [Floating registry death](./heal/floating-registry-death)

## Run

**1. Apply deployments for cluster1:**
Apply NSM resources for basic tests:

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k ../../../../../../../../home/nikita/repos/NSM/deployments-k8s/examples/multicluster/clusters-configuration/cluster1
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
kubectl --kubeconfig=$KUBECONFIG2 apply -k ../../../../../../../../home/nikita/repos/NSM/deployments-k8s/examples/multicluster/clusters-configuration/cluster2
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
kubectl --kubeconfig=$KUBECONFIG3 apply -k ../../../../../../../../home/nikita/repos/NSM/deployments-k8s/examples/multicluster/clusters-configuration/cluster3
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
