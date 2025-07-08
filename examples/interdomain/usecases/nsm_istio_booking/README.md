# NSM + Istio interdomain example

This example deploys [Istio booking example](https://istio.io/latest/docs/examples/bookinfo/) with NSM.

![NSM  interdomain Scheme](./NSM+Istio_Datapath.svg "NSM Basic floating interdomain Scheme")

This diagram shows that we have 2 clusters with NSM and also Istio deployed on the Cluster-2.
As workloads there will be **productpages** on the first and second clusters. Each of the **productpages** requests the services it needs (review and details) according to Istio's example.

Both of these workloads are available to clients - for example, if we make a curl request to the _productpage service_, we can either get to Cluster-1 **_or_** Cluster-2.

This is achieved by adding `istio-proxy-nse` as an endpoint for the productpage Service and additional rules for iptables.

The required steps are listed below.

## Requires

Make sure that you have completed steps from [multiservicemesh](../../suites/multiservicemesh)

## Run

Install Istio for second cluster:
```bash
curl -sL https://istio.io/downloadIstioctl | sh -
export PATH=$PATH:$HOME/.istioctl/bin
istioctl install --readiness-timeout 10m0s --set profile=minimal -y --kubeconfig=$KUBECONFIG2
istioctl --kubeconfig=$KUBECONFIG2 proxy-status
```


Install networkservice for the second cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/f73a0ea8bc713c3e5312625dd44364aba1788ca7/examples/interdomain/usecases/nsm_istio_booking/netsvc.yaml
```

Start `productpage` networkservicemesh client for the first cluster:

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/f73a0ea8bc713c3e5312625dd44364aba1788ca7/examples/interdomain/usecases/nsm_istio_booking/productpage/productpage.yaml
```

Start `auto-scale` networkservicemesh endpoint:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/usecases/nsm_istio_booking/nse-auto-scale?ref=f73a0ea8bc713c3e5312625dd44364aba1788ca7
```

Install istio booking example
```bash
kubectl --kubeconfig=$KUBECONFIG2 label namespace default istio-injection=enabled

kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/istio/istio/release-1.13/samples/bookinfo/platform/kube/bookinfo.yaml
```

Wait for the deploy/productpage-v1 client to be ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --timeout=5m --for=condition=ready pod -l app=productpage
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
kubectl --kubeconfig=$KUBECONFIG2 delete -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/usecases/nsm_istio_booking/nse-auto-scale?ref=f73a0ea8bc713c3e5312625dd44364aba1788ca7 
kubectl --kubeconfig=$KUBECONFIG1 delete -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/f73a0ea8bc713c3e5312625dd44364aba1788ca7/examples/interdomain/usecases/nsm_istio_booking/productpage/productpage.yaml
kubectl --kubeconfig=$KUBECONFIG2 delete -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/f73a0ea8bc713c3e5312625dd44364aba1788ca7/examples/interdomain/usecases/nsm_istio_booking/netsvc.yaml
kubectl --kubeconfig=$KUBECONFIG2 delete ns istio-system
kubectl --kubeconfig=$KUBECONFIG2 label namespace default istio-injection-
kubectl --kubeconfig=$KUBECONFIG2 delete pods --all
```
