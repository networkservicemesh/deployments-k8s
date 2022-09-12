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

Предподготовка:
1. добавить priveleged security context для всех подов
2. Добавить http server (как в istio): добавить большой текст, кт сервер будет возвращать по запросу
3. выключить health check c cmd-nsc (webhook)
Итерация 1:

Nhfrnjh123!
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


Install networkservice for the second cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG2 create ns ns-nsm-linkerd
kubectl --kubeconfig=$KUBECONFIG2 apply -f ./cluster2/netsvc.yaml
```

Start `web-svc` with networkservicemesh client on the first cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k ./cluster1
```

Start `auto-scale` networkservicemesh endpoint:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k ./cluster2
```

Inject Linkerd into emojivoto services and install:
```bash
export KUBECONFIG=$KUBECONFIG2
kubectl get -n ns-nsm-linkerd deploy voting emoji vote-bot -o yaml | linkerd inject - | kubectl apply -f -
```

Wait for the emojivoto pods to be ready on both clusters:
```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --timeout=2m --for=condition=ready pod -l app=voting-svc -n ns-nsm-linkerd
kubectl --kubeconfig=$KUBECONFIG1 wait --timeout=2m --for=condition=ready pod -l app=web-svc -n ns-nsm-linkerd
kubectl --kubeconfig=$KUBECONFIG2 wait --timeout=2m --for=condition=ready pod -l app=emoji-svc -n ns-nsm-linkerd
kubectl --kubeconfig=$KUBECONFIG2 wait --timeout=2m --for=condition=ready pod -l app=vote-bot -n ns-nsm-linkerd
```

Get curl for nsc:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec deploy/web -n ns-nsm-linkerd -c cmd-nsc -- apk add curl
```
Verify connectivity:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec deploy/web -n ns-nsm-linkerd -c cmd-nsc -- curl -v emoji-svc.ns-nsm-linkerd:8080
```
emoji-svc.ns-nsm-linkerd.cvc.cluster.local:8080
## Cleanup

Uninject linkerd proxy from deployments:
```bash
kubectl --kubeconfig=$KUBECONFIG2 get deploy -n ns-nsm-linkerd -o yaml | linkerd uninject - | kubectl apply -f -
```
Delete network service:
```bash
export KUBECONFIG=$KUBECONFIG2
kubectl delete -n ns-nsm-linkerd networkservices.networkservicemesh.io nsm-linkerd
```

export PATH="${PATH}:${HOME}/.krew/bin"

kubectl krew install sniff

Delete namespace:
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete ns ns-nsm-linkerd
kubectl --kubeconfig=$KUBECONFIG2 delete ns ns-nsm-linkerd
```
Remove Linkerd control plane from cluster:
```bash
linkerd uninstall | kubectl delete -f -
```