# Test kernel to kernel connection with excluded prefixes on the client

This example shows kernel to kernel example where we exclude prefixes used by 2 service endpoints on the client side. 

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/da0228654084085b3659ed6b519f66f44b6796ce/examples/use-cases/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

Create customization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE}

resources:
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/da0228654084085b3659ed6b519f66f44b6796ce/examples/features/exclude-prefixes-client/test-client.yaml
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/da0228654084085b3659ed6b519f66f44b6796ce/examples/features/exclude-prefixes-client/nsm-service-1.yaml
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/da0228654084085b3659ed6b519f66f44b6796ce/examples/features/exclude-prefixes-client/nsm-service-2.yaml
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/da0228654084085b3659ed6b519f66f44b6796ce/examples/features/exclude-prefixes-client/nse-kernel-1.yaml
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/da0228654084085b3659ed6b519f66f44b6796ce/examples/features/exclude-prefixes-client/nse-kernel-2.yaml
EOF
```

Deploy NSC, services and NSEs:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel-1 -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel-2 -n ${NAMESPACE}
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=alpine -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE1=$(kubectl get pods -l app=nse-kernel-1 -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE2=$(kubectl get pods -l app=nse-kernel-2 -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE1:
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- ping -c 4 172.16.1.96
```

Ping from NSC to NSE2:
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- ping -c 4 172.16.1.98
```

Ping from NSE1 to NSC:
```bash
kubectl exec ${NSE1} -n ${NAMESPACE} -- ping -c 4 172.16.1.97
```

Ping from NSE2 to NSC:
```bash
kubectl exec ${NSE2} -n ${NAMESPACE} -- ping -c 4 172.16.1.99
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ${NAMESPACE}
```
