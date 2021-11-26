# Test kernel to remote vlan connection

This example shows that NSCs can connect to a cluster external entity by a VLAN interface.
NSCs are using the `kernel` mechanism to connect to local forwarder.
Forwarders are using the `vlan` remote mechanism to set up the VLAN interface.

## Requires

Make sure that you have completed steps from [remotevlan](../../remotevlan) setup.

## Run

Create test namespace:

```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/7dde61822c0256ccb4aef4e4c33d4fb9341a0296/examples/use-cases/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

Create first iperf server deployment:

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

Deploy the iperf-NSCs:

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

Start an iperf server in NSC:

```bash
IS_FIRST=$(kubectl exec ${NSCS[0]} -c iperf-server -n ${NAMESPACE} -- ip a s nsm-1 | grep 172.10.0.1)
if [ -n "$IS_FIRST" ]; then
  kubectl exec ${NSCS[0]} -c iperf-server -n ${NAMESPACE} -- iperf3 -sD -B 172.10.0.1 -1
  kubectl exec ${NSCS[1]} -c iperf-server -n ${NAMESPACE} -- iperf3 -i0 t 5 -c 172.10.0.1 -B 172.10.0.2
else
  kubectl exec ${NSCS[1]} -c iperf-server -n ${NAMESPACE} -- iperf3 -sD -B 172.10.0.1 -1
  kubectl exec ${NSCS[0]} -c iperf-server -n ${NAMESPACE} -- iperf3 -i0 t 5 -c 172.10.0.1 -B 172.10.0.2
fi
```

Create a docker image for test external connections:

```bash
cat > Dockerfile <<EOF
FROM networkstatic/iperf3

RUN apt-get update \
    && apt-get install -y ethtool tcpdump \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT [ "tail", "-f", "/dev/null" ]
EOF
docker build . -t rvm-tester
```

Setup a docker container for traffic test:

```bash
docker run --cap-add=NET_ADMIN --rm -d --network bridge-2 --name rvm-tester rvm-tester tail -f /dev/null
docker exec rvm-tester ip link set eth0 down
docker exec rvm-tester ip link add link eth0 name eth0.100 type vlan id 100
docker exec rvm-tester ip link set eth0 up
docker exec rvm-tester ip addr add 172.10.0.254/24 dev eth0.100
docker exec rvm-tester ethtool -K eth0 tx off
```

Start the client from tester container:

```bash
docker exec rvm-tester ping -c 1 172.10.0.1
```

Start iperf client on tester:

```bash
IS_FIRST=$(kubectl exec ${NSCS[0]} -c iperf-server -n ${NAMESPACE} -- ip a s nsm-1 | grep 172.10.0.1)
if [ -n "$IS_FIRST" ]; then
  kubectl exec ${NSCS[0]} -c iperf-server -n ${NAMESPACE} -- iperf3 -sD -B 172.10.0.1 -1
else
  kubectl exec ${NSCS[1]} -c iperf-server -n ${NAMESPACE} -- iperf3 -sD -B 172.10.0.1 -1
fi
docker exec rvm-tester iperf3 -i0 t 5 -c 172.10.0.1
```

Start iperf server on tester:

```bash
docker exec rvm-tester iperf3 -sD -B 172.10.0.254 -1
kubectl exec ${NSCS[0]} -c iperf-server -n ${NAMESPACE} -- iperf3 -i0 t 5 -c 172.10.0.254
```

## Cleanup

Delete the tester container and image:

```bash
docker stop rvm-tester
docker image rm rvm-tester:latest
true
```

Delete the test namespace:

```bash
kubectl delete ns ${NAMESPACE}
```
