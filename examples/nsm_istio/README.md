# NSM + Istio interdomain example over kind clusters

This example show how can be used nsm over 

![NSM  interdomain Scheme](./NSM+Istio_Datapath.svg "NSM Basic floating interdomain Scheme")


## Requires

- [Load balancer](./loadbalancer)
- [Interdomain DNS](./dns)
- [Interdomain spire](./spire)
- [Interdomain nsm](./nsm)


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

kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/istio/istio/release-1.13/samples/bookinfo/platform/kube/bookinfo.yaml
```

Get curl for nsc:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec deploy/productpage-v1 -c cmd-nsc -- apk add curl
```

Verify connectivity:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec deploy/productpage-v1 -c cmd-nsc -- curl -s productpage.default:9080/productpage | grep -o "<title>Simple Bookstore App</title>"
```
**Expected output** is `<title>Simple Bookstore App</title>`

Congratulations! 
You have made a interdomain connection between two clusters via NSM + Istio!

## Cleanup


```bash
kubectl --kubeconfig=$KUBECONFIG2 delete -f https://raw.githubusercontent.com/istio/istio/release-1.13/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl --kubeconfig=$KUBECONFIG2 delete -k nse-auto-scale 
kubectl --kubeconfig=$KUBECONFIG1 delete -f productpage/productpage.yaml
kubectl --kubeconfig=$KUBECONFIG2 delete -f networkservice.yaml
kubectl --kubeconfig=$KUBECONFIG2 delete ns istio-system
kubectl --kubeconfig=$KUBECONFIG2 label namespace default istio-injection-
kubectl --kubeconfig=$KUBECONFIG2 delete pods --all
```
