# NSM + Istio interdomain example over kind clusters

This example show how can be used nsm over 

![NSM  interdomain Scheme](./NSM+Istio_Datapath.svg "NSM Basic floating interdomain Scheme")


## Requires

- [Load balancer](../basic_interdomain/loadbalancer)
- [Interdomain DNS](../basic_interdomain/dns)
- [Interdomain spire](../basic_interdomain/spire)
- [Interdomain nsm](../basic_interdomain/nsm)


## Run

Install Istio for second cluster:
```bash
curl -sL https://istio.io/downloadIstioctl | sh -
export PATH=$PATH:$HOME/.istioctl/bin
istioctl  install --set profile=minimal -y --kubeconfig=$KUBECONFIG2
istioctl --kubeconfig=$KUBECONFIG2 proxy-status
```


Install networkservice for the second cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f networkservice.yaml
```

Start `productpage` networkservicemesh client for the first cluster:

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f productpage/productpage.yaml
```

Start `auto-scale` networkservicemesh endpoint:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k nse-auto-scale 
```

Install istio booking example
```bash
kubectl --kubeconfig=$KUBECONFIG2 label namespace default istio-injection=enabled

kubectl --kubeconfig=$KUBECONFIG2 apply -f productpage/productpage_ci.yaml
```

Wait for the deploy/productpage-v1 client to be ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --timeout=2m --for=condition=ready pod -l app=productpage
```

Get curl for nsc:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec deploy/productpage-v1 -c cmd-nsc -- apk add curl
```

Verify connectivity:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec deploy/productpage-v1 -c cmd-nsc -- curl -s productpage.default:9080/productpage
```
**Expected output** is "hello world from istio"

Congratulations! 
You have made a interdomain connection between two clusters via NSM + Istio!

## Cleanup

```bash
kubectl --kubeconfig=$KUBECONFIG1 get pods -A
```

```bash
kubectl --kubeconfig=$KUBECONFIG2 get pods -A
```

```bash
kubectl --kubeconfig=$KUBECONFIG1 logs deploy/productpage-v1 -c cmd-nsc-init
```

```bash
NSE=$(kubectl get pods -l app=productpage,spiffe.io/spiffe-id=true --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 logs $NSE -c nse
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 logs -l app=nse-supplier-k8s
```

```bash
kubectl --kubeconfig=$KUBECONFIG2 describe pods
```

```bash
kubectl --kubeconfig=$KUBECONFIG2 delete -f https://raw.githubusercontent.com/istio/istio/release-1.13/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl --kubeconfig=$KUBECONFIG2 delete -k nse-auto-scale 
kubectl --kubeconfig=$KUBECONFIG1 delete -f productpage/productpage.yaml
kubectl --kubeconfig=$KUBECONFIG2 delete -f networkservice.yaml
kubectl --kubeconfig=$KUBECONFIG2 delete ns istio-system
kubectl --kubeconfig=$KUBECONFIG2 label namespace default istio-injection-
kubectl --kubeconfig=$KUBECONFIG2 delete pods --all
```
