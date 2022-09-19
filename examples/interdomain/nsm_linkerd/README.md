# Test NSM and Linkerd integration


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
If on some step you've got error, resolve and repeat step.

Install networkservice for the second cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG2 create ns ns-nsm-linkerd
kubectl --kubeconfig=$KUBECONFIG2 apply -f ./cluster2/netsvc.yaml
```

Start `auto-scale` networkservicemesh endpoint and greeting service on the second cluster. 
Proxy pod has injected Linkerd sidecars with annotations:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k ./cluster2/nse-auto-scale
kubectl --kubeconfig=$KUBECONFIG2 apply -n ns-nsm-linkerd -f ./cluster2/web-svc.yaml
```

Inject Linkerd proxy and debug sidecars into greeting service and install:
```bash
export KUBECONFIG=$KUBECONFIG2
kubectl get -n ns-nsm-linkerd deploy greeting -o yaml | linkerd inject --enable-debug-sidecar - | kubectl apply -f -
```

Wait for the pods to be ready on the second clusters:
```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --timeout=2m --for=condition=ready pod -l app=web-local-svc -n ns-nsm-linkerd
kubectl --kubeconfig=$KUBECONFIG2 wait --timeout=2m --for=condition=ready pod -l app=greeting -n ns-nsm-linkerd
```

Install required packages for work with iptables:
```bash
export KUBECONFIG=$KUBECONFIG2
kubectl exec -n ns-nsm-linkerd $PROXY_LOCAL -it -c nse --  apk add curl
kubectl exec -n ns-nsm-linkerd $PROXY_LOCAL -it -c nse --  apk add iptables
kubectl exec -n ns-nsm-linkerd $PROXY_LOCAL -it -c nse --  iptables -t nat -L
```

You can use linkerd debug sidecar to get logs:
```bash
kubectl --kubeconfig=$KUBECONFIG2 logs $PROXY_LOCAL linkerd-debug -n ns-nsm-linkerd  > proxy-web-local-linkerd-exp2.log
```

Get curl for nsc:
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec deploy/web-local -n ns-nsm-linkerd -c cmd-nsc -- apk add curl
```
Verify connectivity:
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec deploy/web-local -n ns-nsm-linkerd -c cmd-nsc -- curl -v greeting.ns-nsm-linkerd:8080
```
If something went wrong, add new rule to PROXY_LOCAL IPtables and try again.

If you are using VM to run this example, you can use Ksniff utilite to analyse traffic with Wireshark later https://github.com/eldadru/ksniff:
```bash
kubectl krew install sniff
```

```bash
kubectl sniff $PROXY_LOCAL -n ns-nsm-linkerd -c nse -o exp1/proxy-local-nse.pcap
```

Interdomain integration:
To check and adjust intercluster communication start `web-svc` with networkservicemesh client on the first cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k ./cluster1
```

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

