# NSM interdomain setup


This example simply show how can be deployed and configured two NSM on different clusters

## Run

Install NSM
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm/cluster1?ref=f2ad23a3cb9b1c7ba4f23f464a2cd423a0263e71
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm/cluster2?ref=f2ad23a3cb9b1c7ba4f23f464a2cd423a0263e71
```

Wait for admission-webhook-k8s:
```bash
WH=$(kubectl --kubeconfig=$KUBECONFIG1 get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system

WH=$(kubectl --kubeconfig=$KUBECONFIG2 get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```

## Cleanup

Cleanup NSM
```bash
WH=$(kubectl --kubeconfig=$KUBECONFIG1 get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl --kubeconfig=$KUBECONFIG1 delete mutatingwebhookconfiguration ${WH}

WH=$(kubectl --kubeconfig=$KUBECONFIG2 get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl --kubeconfig=$KUBECONFIG2 delete mutatingwebhookconfiguration ${WH}

kubectl --kubeconfig=$KUBECONFIG1 delete -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm/cluster1?ref=f2ad23a3cb9b1c7ba4f23f464a2cd423a0263e71
kubectl --kubeconfig=$KUBECONFIG2 delete -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm/cluster2?ref=f2ad23a3cb9b1c7ba4f23f464a2cd423a0263e71
```
