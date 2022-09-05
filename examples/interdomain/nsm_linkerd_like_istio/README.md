# Test automatic scale from zero

This example shows that NSEs can be created on the fly on NSC requests.
This allows effective scaling for endpoints.
The requested endpoint will be automatically spawned on the same node as NSC (see step 12),
allowing the best performance for connectivity.

Here we are using an endpoint that automatically shuts down
when it has no active connection for specified time.
We are using very short timeout for the purpose of the test: 15 seconds.

We are only using one client in this test,
so removing it (see step 13) will cause the NSE to shut down.

Supplier watches for endpoints it created
and clears endpoints that finished their work,
thus saving cluster resources (see step 14).

## Run

Install Linkerd CLI:
```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```
Verify Linkerd CLI is installed:
```bash
linkerd version
```
If not, export linkerd path to $PATH:
```bash
export PATH=$PATH:/home/amalysheva/.linkerd2/bin
```

Install Linkerd onto 2nd cluster:
```bash
export KUBECONFIG=$KUBECONFIG2
linkerd check --pre
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -
linkerd check
```

Create test namespace:
```bash
kubectl create ns ns-nsm-linkerd
```

Install networkservice for the second cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f ./cluster2/networkservice.yaml
```
Start `alpine` with networkservicemesh client on the first cluster:

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f ./cluster1/client.yaml
```

Start `auto-scale` networkservicemesh endpoint:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k ./cluster2/nse-auto-scale
```

Inject Linkerd into 'voting' server and install:
```bash
cat ./cluster2/voting.yml | linkerd inject - | kubectl apply -f -
```

Wait for the `alpine` client to be ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --timeout=2m --for=condition=ready pod -l app=alpine -n ns-nsm-linkerd
```

Wait for the `voting` server to be ready:
```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --timeout=2m --for=condition=ready pod -l app=voting-svc -n ns-nsm-linkerd
```

Get curl for nsc:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec deploy/alpine -n ns-nsm-linkerd -c cmd-nsc -- apk add curl
```
Verify connectivity:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec deploy/alpine -n ns-nsm-linkerd -c cmd-nsc -- curl -s voting-svc.emojivoto:8080
```



## Cleanup

Uninject linkerd proxy from deployments:
```bash
kubectl get -n ns-nsm-linkerd deploy nsc-kernel -o yaml | linkerd uninject - | kubectl apply -f -
```
Delete namespace:
```bash
kubectl delete ns ns-nsm-linkerd
```
Delete network service:
```bash
kubectl delete -n nsm-system networkservices.networkservicemesh.io autoscale-icmp-responder
```
Remove Linkerd control plane from cluster:
```bash
linkerd uninstall | kubectl delete -f -
```