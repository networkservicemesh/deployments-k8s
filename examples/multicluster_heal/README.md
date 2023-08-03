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

- [Forwarders death in floating interdomain scenario](./usecases/floating-forwarder-death)
- [NSE death in floating interdomain scenario](./usecases/floating-nse-death)
- [NSM systems death in floating interdomain scenario](./usecases/floating-nsm-system-death)
- [Proxy nsmgrs death in interdomain scenario](./usecases/interdomain-proxy-nsmgr-death)
- [NSMGRs death in interdomain scenario](./usecases/interdomain-nsmgr-death)
- [Registry death in interdomain scenario](./usecases/interdomain-registry-death)

## Run

**1. Apply deployments for cluster1:**
Apply NSM resources for basic tests:

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster_heal/clusters-configuration/cluster1?ref=b7a0736c9257da4c7e0880b8338f254f94097d4c
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
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster_heal/clusters-configuration/cluster2?ref=b7a0736c9257da4c7e0880b8338f254f94097d4c
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
kubectl --kubeconfig=$KUBECONFIG3 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster_heal/clusters-configuration/cluster3?ref=b7a0736c9257da4c7e0880b8338f254f94097d4c
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
