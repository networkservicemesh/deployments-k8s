# Test kernel to remote vlan connection

This example shows that NSCs can connect to each other by VLAN interface.
NSCs are using the `kernel` mechanism to connect to local forwarder.
Forwarders are using the `vlan` remote mechanism to set up the VLAN interface.

## Requires

Make sure that you have completed steps from [remotevlan](../../remotevlan) setup.

## Run

Create test namespace:

```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/7758662e8a91c411ed8740e9f76c3c921d87d321/examples/use-cases/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

Create iperf server deployment:

```bash
cat > first-iperf-s.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: iperf1-s
  labels:
    app: iperf1-s
spec:
  replicas: 2
  selector:
    matchLabels:
      app: iperf1-s
  template:
    metadata:
      labels:
        app: iperf1-s
      annotations:
        networkservicemesh.io: kernel://finance-bridge/nsm-1
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - iperf1-s
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: iperf-server
        image: networkstatic/iperf3:latest
        imagePullPolicy: IfNotPresent
        command: ["tail", "-f", "/dev/null"]
EOF
```

Create kustomization file:

```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE}

resources:
- first-iperf-s.yaml

EOF
```

Deploy the application:

```bash
kubectl apply -k .
```

Wait for applications ready:

```bash
kubectl -n ${NAMESPACE} wait --for=condition=ready --timeout=1m pod -l app=iperf1-s
```

Get the iperf-NSC pods:

```bash
NSCS=($(kubectl get pods -l app=iperf1-s -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'))
```

Start an iperf server in one NSC and client in another:

1. TCP with IPv4

    ```bash
    IP_ADDR=$(kubectl exec ${NSCS[0]} -c cmd-nsc -n ${NAMESPACE} -- ip -4 addr show nsm-1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    kubectl exec ${NSCS[0]} -c iperf-server -n ${NAMESPACE} -- iperf3 -sD -B ${IP_ADDR} -1
    kubectl exec ${NSCS[1]} -c iperf-server -n ${NAMESPACE} -- iperf3 -i0 -t 5 -c ${IP_ADDR}
    ```

2. UDP with IPv4:

    ```bash
    IP_ADDR=$(kubectl exec ${NSCS[1]} -c cmd-nsc -n ${NAMESPACE} -- ip -4 addr show nsm-1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    kubectl exec ${NSCS[1]} -c iperf-server -n ${NAMESPACE} -- iperf3 -sD -B ${IP_ADDR} -1
    kubectl exec ${NSCS[0]} -c iperf-server -n ${NAMESPACE} -- iperf3 -i0 -t 5 -u -c ${IP_ADDR}
    ```

3. TCP with IPv6:

    ```bash
    IP_ADDR=$(kubectl exec ${NSCS[0]} -c cmd-nsc -n ${NAMESPACE} -- ip -6 a s nsm-1 scope global | grep -oP '(?<=inet6\s)([0-9a-f:]+:+)+[0-9a-f]+')
    kubectl exec ${NSCS[0]} -c iperf-server -n ${NAMESPACE} -- iperf3 -sD -B ${IP_ADDR} -1
    kubectl exec ${NSCS[1]} -c iperf-server -n ${NAMESPACE} -- iperf3 -i0 -t 5 -6 -c ${IP_ADDR}
    ```

4. UDP with IPv6:

    ```bash
    IP_ADDR=$(kubectl exec ${NSCS[1]} -c cmd-nsc -n ${NAMESPACE} -- ip -6 a s nsm-1 scope global | grep -oP '(?<=inet6\s)([0-9a-f:]+:+)+[0-9a-f]+')
    kubectl exec ${NSCS[1]} -c iperf-server -n ${NAMESPACE} -- iperf3 -sD -B ${IP_ADDR} -1
    kubectl exec ${NSCS[0]} -c iperf-server -n ${NAMESPACE} -- iperf3 -i0 -t 5 -6 -u -c ${IP_ADDR}
    ```

## Cleanup

Delete the test namespace:

```bash
kubectl delete ns ${NAMESPACE}
```
