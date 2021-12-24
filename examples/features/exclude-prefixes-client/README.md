# Test kernel to kernel connection with excluded prefixes on the client

This example shows kernel to kernel example where we exclude prefixes used by 2 service endpoints on the client side. 

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/eea3ba374aae962a76875f0c25a2091dce29c569/examples/use-cases/namespace.yaml)[0])
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
- test-client.yaml
- nsm-service-1.yaml
- nsm-service-2.yaml
- nse-kernel-1.yaml
- nse-kernel-2.yaml
EOF
```

Create Client:
```bash
cat > test-client.yaml <<EOF
---
apiVersion: v1
kind: Pod
metadata:
  name: alpine
  labels:
    app: alpine
  annotations:
    networkservicemesh.io: kernel://nsm-service-1/nsm-1,kernel://nsm-service-2/nsm-2
spec:
  containers:
  - name: alpine
    image: alpine:3.15.0
    imagePullPolicy: IfNotPresent
    stdin: true
    tty: true
EOF
```

Create first service:
```bash
cat > nsm-service-1.yaml <<EOF
---
apiVersion: networkservicemesh.io/v1
kind: NetworkService
metadata:
  name: nsm-service-1
spec:
  payload: ETHERNET
EOF
```

Create second service:
```bash
cat > nsm-service-2.yaml <<EOF
---
apiVersion: networkservicemesh.io/v1
kind: NetworkService
metadata:
  name: nsm-service-2
spec:
  payload: ETHERNET
EOF
```

Create an endpoint for the first service:
```bash
cat > nse-kernel-1.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse-kernel-1
  labels:
    app: nse-kernel-1
spec:
  selector:
    matchLabels:
      app: nse-kernel-1
  template:
    metadata:
      labels:
        app: nse-kernel-1
        "spiffe.io/spiffe-id": "true"
    spec:
      containers:
        - name: nse
          image: ghcr.io/networkservicemesh/ci/cmd-nse-icmp-responder:9b33c26
          imagePullPolicy: IfNotPresent
          env:
            - name: SPIFFE_ENDPOINT_SOCKET
              value: unix:///run/spire/sockets/agent.sock
            - name: NSM_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: NSM_LOG_LEVEL
              value: TRACE
            - name: NSM_CONNECT_TO
              value: unix:///var/lib/networkservicemesh/nsm.io.sock
            - name: NSM_REGISTER_SERVICE
              value: "false"
            - name: NSM_CIDR_PREFIX
              value: 172.16.1.96/29
            - name: NSM_SERVICE_NAMES
              value: nsm-service-1
          volumeMounts:
            - name: spire-agent-socket
              mountPath: /run/spire/sockets
              readOnly: true
            - name: nsm-socket
              mountPath: /var/lib/networkservicemesh
              readOnly: true
          resources:
            requests:
              cpu: 100m
              memory: 40Mi
            limits:
              memory: 80Mi
              cpu: 200m
      volumes:
        - name: spire-agent-socket
          hostPath:
            path: /run/spire/sockets
            type: Directory
        - name: nsm-socket
          hostPath:
            path: /var/lib/networkservicemesh
            type: DirectoryOrCreate
EOF
```

Create an endpoint for the second service:
```bash
cat > nse-kernel-2.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse-kernel-2
  labels:
    app: nse-kernel-2
spec:
  selector:
    matchLabels:
      app: nse-kernel-2
  template:
    metadata:
      labels:
        app: nse-kernel-2
        "spiffe.io/spiffe-id": "true"
    spec:
      containers:
        - name: nse
          image: ghcr.io/networkservicemesh/ci/cmd-nse-icmp-responder:9b33c26
          imagePullPolicy: IfNotPresent
          env:
            - name: SPIFFE_ENDPOINT_SOCKET
              value: unix:///run/spire/sockets/agent.sock
            - name: NSM_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: NSM_LOG_LEVEL
              value: TRACE
            - name: NSM_CONNECT_TO
              value: unix:///var/lib/networkservicemesh/nsm.io.sock
            - name: NSM_REGISTER_SERVICE
              value: "false"
            - name: NSM_CIDR_PREFIX
              value: 172.16.1.96/29
            - name: NSM_SERVICE_NAMES
              value: nsm-service-2
          volumeMounts:
            - name: spire-agent-socket
              mountPath: /run/spire/sockets
              readOnly: true
            - name: nsm-socket
              mountPath: /var/lib/networkservicemesh
              readOnly: true
          resources:
            requests:
              cpu: 100m
              memory: 40Mi
            limits:
              memory: 80Mi
              cpu: 200m
      volumes:
        - name: spire-agent-socket
          hostPath:
            path: /run/spire/sockets
            type: Directory
        - name: nsm-socket
          hostPath:
            path: /var/lib/networkservicemesh
            type: DirectoryOrCreate
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
