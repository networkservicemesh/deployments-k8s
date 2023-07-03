# Nsm system restart (local case)

This example shows that NSM keeps working after restarting all management resources.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.

## Requires

Make sure that you have completed steps from [basic](../../basic).

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/local-nsm-system-restart?ref=75f1163ad94e3f9ad4c85681413379e86f16b036
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-local-nsm-system-restart
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-local-nsm-system-restart
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-local-nsm-system-restart -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-local-nsm-system-restart -- ping -c 4 172.16.1.101
```

Restart nsm-system:
```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl delete mutatingwebhookconfiguration ${WH}
kubectl delete ns nsm-system
```
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/basic?ref=75f1163ad94e3f9ad4c85681413379e86f16b036
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-local-nsm-system-restart -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-local-nsm-system-restart -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-local-nsm-system-restart
```
