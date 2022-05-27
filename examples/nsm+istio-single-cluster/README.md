# NSM + Istio interdomain example over kind cluster

## Setup Cluster

### KIND
Setup

```bash
go install sigs.k8s.io/kind@v0.13.0 

kind create cluster --config kind-cluster-config.yaml
```


## SPIRE & NSM

Use instructions from [Basic](../basic/README.md)


## Istio

Install Istio for a cluster:
```bash
curl -sL https://istio.io/downloadIstioctl | sh -
export PATH=$PATH:$HOME/.istioctl/bin
istioctl install --set profile=minimal -y
istioctl proxy-status
```

### Verify NSM+ISTIO

Install networkservice:
```bash
kubectl apply -f networkservice.yaml
```

Start `productpage` networkservicemesh client:

```bash
kubectl apply -f productpage/productpage.yaml
```

Start `auto-scale` networkservicemesh endpoint:
```bash
kubectl apply -k nse-auto-scale 
```

Install istio booking example
```bash
kubectl label namespace default istio-injection=enabled

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.13/samples/bookinfo/platform/kube/bookinfo.yaml
```

Verify connectivity:
```bash
kubectl exec deploy/productpage-v2 -c cmd-nsc -- apk add curl
kubectl exec deploy/productpage-v2 -c cmd-nsc -- curl -s productpage.default:9080/productpage | grep -o "<title>.*</title>"
```
**Expected output** is `<title>Simple Bookstore App</title>`


Port forward and check connectivity from NSM+Istio by yourself!
```bash
kubectl port-forward deploy/productpage-v1 9080:9080
```

**Note:**
You should correctly see the page without errors.

Also, you should see different backend handlers for your requests:
If `reviews-v1` handles your query then you will not see reviews.
If `reviews-v2` handles your query then you will see black stars.
If `reviews-v3` handles your query then you will see red stars.
Otherwise you will see an error message.


Now we're simulating that someting went wrong and ratings-v1 from the istio cluster is down.
```bash
kubectl delete deploy ratings-v1
```


Port forward and check that you see errors:
```bash
kubectl port-forward deploy/productpage-v1  9080:9080
```

Now lets start ratings with nsm:
```bash
kubectl apply -f ratings/ratings.yaml
```

Port forward and check that you dont errors:
```bash
kubectl port-forward deploy/productpage-v1  9080:9080
```

Congratulations! 
You have made a connection via NSM + Istio!

## Cleanup


```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl delete mutatingwebhookconfiguration ${WH}

kubectl delete crd spiffeids.spiffeid.spiffe.io
kubectl delete ns spire

kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.13/samples/bookinfo/platform/kube/bookinfo.yaml

kubectl delete -k nse-auto-scale 

kubectl delete -f productpage/productpage.yaml

kubectl delete -f networkservice.yaml
kubectl delete ns istio-system
kubectl label namespace default istio-injection-
kubectl delete pods --all

kind delete cluster
```
