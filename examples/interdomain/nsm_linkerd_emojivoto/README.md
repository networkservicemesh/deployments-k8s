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
kubectl --kubeconfig=$KUBECONFIG1 apply -k ./cluster1
```

Start `auto-scale` networkservicemesh endpoint:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k ./cluster2/nse-auto-scale
```

Inject Linkerd into emojivoto services and install:
```bash
export KUBECONFIG=$KUBECONFIG2
linkerd inject - ./cluster2/emojivoto | kubectl apply -f -
```

Wait for the `alpine` client to be ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --timeout=2m --for=condition=ready pod -l app=alpine -n ns-nsm-linkerd
```

Wait for the wmojivoto pods to be ready:
```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --timeout=2m --for=condition=ready pod -l app=voting-svc -n ns-nsm-linkerd
kubectl --kubeconfig=$KUBECONFIG2 wait --timeout=2m --for=condition=ready pod -l app=web-svc -n ns-nsm-linkerd
kubectl --kubeconfig=$KUBECONFIG2 wait --timeout=2m --for=condition=ready pod -l app=emoji-svc -n ns-nsm-linkerd
kubectl --kubeconfig=$KUBECONFIG2 wait --timeout=2m --for=condition=ready pod -l app=vote-bot -n ns-nsm-linkerd
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
kubectl --kubeconfig=$KUBECONFIG2 get -n ns-nsm-linkerd deploy -o yaml | linkerd uninject - | kubectl apply -f -
```
Delete network service:
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete -n nsm-system networkservices.networkservicemesh.io nsm-linkerd
```

Delete namespace:
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete ns ns-nsm-linkerd
kubectl --kubeconfig=$KUBECONFIG2 delete ns ns-nsm-linkerd
```
Remove Linkerd control plane from cluster:
```bash
linkerd uninstall | kubectl delete -f -
```