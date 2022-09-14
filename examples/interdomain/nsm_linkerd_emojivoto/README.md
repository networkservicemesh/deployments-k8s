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
kubectl get -n ns-nsm-linkerd deploy voting emoji vote-bot greeting -o yaml | linkerd inject - | kubectl apply -f -
```

```bash
export KUBECONFIG=$KUBECONFIG2
kubectl get -n ns-nsm-linkerd pod proxy-web-659544f5f7-nsdlk proxy-web-6b86db9f49-b8tpf -o yaml \
  | linkerd inject --enable-debug-sidecar - \
  | kubectl apply -f -
```


```bash
export KUBECONFIG=$KUBECONFIG2
kubectl get -n ns-nsm-linkerd deploy voting emoji vote-bot greeting -o yaml \
  | linkerd inject --enable-debug-sidecar - \
  | kubectl apply -f -
```
```bash
kubectl logs -n ns-nsm-linkerd pod proxy-web-659544f5f7-nsdlk linkerd-debug -f
```

kubectl get pods -n ns-nsm-linkerd
kubectl --kubeconfig=$KUBECONFIG2 get pods -n ns-nsm-linkerd

Wait for the emojivoto pods to be ready on both clusters:
```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --timeout=2m --for=condition=ready pod -l app=voting-svc -n ns-nsm-linkerd
kubectl --kubeconfig=$KUBECONFIG1 wait --timeout=2m --for=condition=ready pod -l app=web-svc -n ns-nsm-linkerd
kubectl --kubeconfig=$KUBECONFIG2 wait --timeout=2m --for=condition=ready pod -l app=emoji-svc -n ns-nsm-linkerd
kubectl --kubeconfig=$KUBECONFIG2 wait --timeout=2m --for=condition=ready pod -l app=vote-bot -n ns-nsm-linkerd
```
```bash
PROXY=proxy-web-6b86db9f49-shtps
GREET=greeting-5fc9f6cb8f-7sbg6
EMOJI=emoji-6b44c86496-xrxnx
```

```bash
kubectl exec -n ns-nsm-linkerd $PROXY -it -c nse --  apk add curl
kubectl exec -n ns-nsm-linkerd $PROXY -it -c nse --  apk add iptables
kubectl exec -n ns-nsm-linkerd $PROXY -it -c nse --  iptables -t nat -L
kubectl exec -n ns-nsm-linkerd $PROXY -it -c nse -- curl -v http://emoji-svc.ns-nsm-linkerd:8080
kubectl exec -n ns-nsm-linkerd $PROXY -it -c nse -- curl -v emoji-svc.ns-nsm-linkerd:8080
kubectl exec -n ns-nsm-linkerd $PROXY -it -c nse -- curl -s greeting.ns-nsm-linkerd:9080
```

```bash
kubectl exec -n ns-nsm-linkerd $EMOJI -it -c emoji-svc -- curl -s greeting.ns-nsm-linkerd:9080
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
```bash
kubectl sniff $EMOJI -n ns-nsm-linkerd -c emoji-svc -o emoji-exp1.pcap
```
export KUBECONFIG1=/tmp/config1
export KUBECONFIG2=/tmp/config2
export KUBECONFIG=$KUBECONFIG1
export KUBECONFIG=$KUBECONFIG2

## Cleanup

Uninject linkerd proxy from deployments:
```bash
export PATH=$PATH:/home/amalysheva/.linkerd2/bin
kubectl --kubeconfig=$KUBECONFIG2 get deploy -n ns-nsm-linkerd -o yaml | linkerd uninject - | kubectl apply -f -
```
Delete network service:
```bash
export KUBECONFIG=$KUBECONFIG2
kubectl delete -n ns-nsm-linkerd networkservices.networkservicemesh.io nsm-linkerd
```

export PATH="${PATH}:${HOME}/.krew/bin"

kubectl krew install sniff
kubectl sniff $PROXY -n ns-nsm-linkerd -c nse -o proxy-web-exp1.pcap
kubectl sniff $PROXY -n ns-nsm-linkerd -c nse -o proxy-web-exp1.pcap
kubectl sniff $PROXY -n ns-nsm-linkerd -c nse -o proxy-exp3.pcap
Delete namespace:
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete ns ns-nsm-linkerd
kubectl --kubeconfig=$KUBECONFIG2 delete ns ns-nsm-linkerd
```
Remove Linkerd control plane from cluster:
```bash
linkerd uninstall | kubectl delete -f -
```

