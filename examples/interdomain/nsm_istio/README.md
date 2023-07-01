# NSM + Istio interdomain example over kind clusters

![NSM  interdomain Scheme](./NSM+Istio_Datapath.svg "NSM Basic floating interdomain Scheme")

This diagram shows that we have 2 clusters with NSM and also Istio deployed on the Cluster-2.

In this example, we deploy an http-server (**Workload-2**) on the Cluster-2 and show how it can be reached from Cluster-1.

The client will be `alpine` (**Workload-1**), we will use curl.

## Requires

- [Load balancer](../loadbalancer)
- [Interdomain DNS](../dns)
- Interdomain spire
    - [Spire on first cluster](../../spire/cluster1)
    - [Spire on second cluster](../../spire/cluster2)
    - [Spiffe Federation](../spiffe_federation)
- [Interdomain nsm](../nsm)


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
kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/81efd77eef0341e835083feaafac5e52fabd34a8/examples/interdomain/nsm_istio/netsvc.yaml
```

Start `alpine` with networkservicemesh client on the first cluster:

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/81efd77eef0341e835083feaafac5e52fabd34a8/examples/interdomain/nsm_istio/greeting/client.yaml
```

Start `auto-scale` networkservicemesh endpoint:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm_istio/nse-auto-scale?ref=81efd77eef0341e835083feaafac5e52fabd34a8
```

Install http-server for the second cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG2 label namespace default istio-injection=enabled

kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/81efd77eef0341e835083feaafac5e52fabd34a8/examples/interdomain/nsm_istio/greeting/server.yaml
```

Wait for the `alpine` client to be ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --timeout=5m --for=condition=ready pod -l app=alpine
```

Get curl for nsc:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec deploy/alpine -c cmd-nsc -- apk add curl
```

Verify connectivity:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec deploy/alpine -c cmd-nsc -- curl -s greeting.default:9080 | grep -o "hello world from istio"
```
**Expected output** is "hello world from istio"

Congratulations! 
You have made a interdomain connection between two clusters via NSM + Istio!

## Cleanup

```bash
kubectl --kubeconfig=$KUBECONFIG2 delete -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/81efd77eef0341e835083feaafac5e52fabd34a8/examples/interdomain/nsm_istio/greeting/server.yaml
kubectl --kubeconfig=$KUBECONFIG2 delete -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm_istio/nse-auto-scale?ref=81efd77eef0341e835083feaafac5e52fabd34a8
kubectl --kubeconfig=$KUBECONFIG1 delete -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/81efd77eef0341e835083feaafac5e52fabd34a8/examples/interdomain/nsm_istio/greeting/client.yaml
kubectl --kubeconfig=$KUBECONFIG2 delete -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/81efd77eef0341e835083feaafac5e52fabd34a8/examples/interdomain/nsm_istio/netsvc.yaml
kubectl --kubeconfig=$KUBECONFIG2 delete ns istio-system
kubectl --kubeconfig=$KUBECONFIG2 label namespace default istio-injection-
kubectl --kubeconfig=$KUBECONFIG2 delete pods --all
```
