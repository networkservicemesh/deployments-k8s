# Basic examples

Basis example contains setup and tear down logic with default NSM infrastructure.

## Requires

- [spire](../spire)

## Run

Apply Jaeger, Prometheus and OpenTelemetry Collector:

```bash
kubectl apply -k .
```

Expose ports to access Jaeger and Prometheus UI:

```bash
kubectl port-forward service/jaeger -n observability 16686:16686&
kubectl port-forward service/prometheus -n observability 9090:9090&
```

Create ns for deployments:

```bash
kubectl create ns nsm-system
```

Create customization file:

```bash
cat > nsm-system/kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: nsm-system

bases:
- https://github.com/networkservicemesh/deployments-k8s/examples/memory?ref=b777192bd492104226e3ea75fe05d874a6a725b7

patchesStrategicMerge:
- patch-nsmgr.yaml
- patch-forwarder.yaml
EOF
```

Create NSMGR patch:

```bash
cat > nsm-system/patch-nsmgr.yaml <<EOF
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nsmgr
spec:
  template:
    spec:
      containers:
        - name: nsmgr
          env:
            - name: TELEMETRY
              value: opentelemetry
            - name: COLLECTOR_ADDR
              value: otel-collector.observability.svc.cluster.local:4317
EOF
```

Create forwarder patch:

```bash
cat > nsm-system/patch-forwarder.yaml <<EOF
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: forwarder-vpp
spec:
  template:
    spec:
      containers:
        - name: forwarder-vpp
          env:
            - name: TELEMETRY
              value: opentelemetry
            - name: COLLECTOR_ADDR
              value: otel-collector.observability.svc.cluster.local:4317
EOF
```

Apply NSM resources for basic tests:

```bash
kubectl apply -k nsm-system
```

Wait for admission-webhook-k8s:

```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```

Create test namespace:

```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/774f9f7281bb12a5956d943ea7a5fdd4e040be96/examples/use-cases/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

Select node to deploy NSC and NSE:

```bash
NODE=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}')[0])
```

Create customization file:

```bash
cat > example/kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE}

resources: 
- client.yaml
bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=774f9f7281bb12a5956d943ea7a5fdd4e040be96

patchesStrategicMerge:
- patch-nse.yaml
EOF
```

Create Client:

```bash
cat > example/client.yaml <<EOF
---
apiVersion: v1
kind: Pod
metadata:
  name: alpine
  labels:
    app: alpine    
  annotations:
    networkservicemesh.io: kernel://icmp-responder/nsm-1
spec:
  containers:
  - name: alpine
    image: alpine:3.15.0
    imagePullPolicy: IfNotPresent
    stdin: true
    tty: true
  nodeSelector:
    kubernetes.io/hostname: ${NODE}
EOF
```

Create NSE patch:

```bash
cat > example/patch-nse.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse-kernel
spec:
  template:
    spec:
      containers:
        - name: nse
          env:
            - name: NSM_CIDR_PREFIX
              value: 172.16.1.100/31
            - name: TELEMETRY
              value: opentelemetry
            - name: COLLECTOR_ADDR
              value: otel-collector.observability.svc.cluster.local:4317
      nodeSelector:
        kubernetes.io/hostname: ${NODE}
EOF
```

Deploy NSC and NSE:

```bash
kubectl apply -k example
```

Wait for applications ready:

```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ${NAMESPACE}
```

```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ${NAMESPACE}
```

Find nsc and nse pods by labels:

```bash
NSC=$(kubectl get pods -l app=alpine -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:

```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:

```bash
kubectl exec ${NSE} -n ${NAMESPACE} -- ping -c 4 172.16.1.101
```

## Cleanup

```bash
kubectl delete ns ${NAMESPACE}
```

```bash
kubectl delete mutatingwebhookconfiguration --all
kubectl delete ns nsm-system
```
