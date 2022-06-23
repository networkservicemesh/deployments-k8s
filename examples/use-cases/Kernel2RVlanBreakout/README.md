# Test kernel to remote vlan connection

This example shows that NSCs can connect to a cluster external entity by a VLAN interface.
NSCs are using the `kernel` mechanism to connect to local forwarder.
Forwarders are using the `vlan` remote mechanism to set up the VLAN interface.

## Requires

Make sure that you have completed steps from [remotevlan](../../remotevlan) setup.

## Run

Create test namespace:

```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a/examples/use-cases/namespace.yaml)[0])
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

Deploy the application:

```bash
kubectl apply -n ${NAMESPACE} -f ./first-iperf-s.yaml
```

Wait for applications ready:

```bash
kubectl -n ${NAMESPACE} wait --for=condition=ready --timeout=1m pod -l app=iperf1-s
```

Get the iperf-NSC pods:

```bash
NSCS=($(kubectl get pods -l app=iperf1-s -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'))
```

Create a docker image for test external connections:

```bash
cat > Dockerfile <<EOF
FROM networkstatic/iperf3

RUN apt-get update \
    && apt-get install -y ethtool iproute2 \
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

Start iperf client on tester:

1. TCP

    ```bash
    status=0
    for nsc in "${NSCS[@]}"
    do
      IP_ADDRESS=$(kubectl exec ${nsc} -c cmd-nsc -n ${NAMESPACE} -- ip -4 addr show nsm-1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
      kubectl exec ${nsc} -c iperf-server -n ${NAMESPACE} -- iperf3 -sD -B ${IP_ADDRESS} -1
      docker exec rvm-tester iperf3 -i0 -t 25 -c ${IP_ADDRESS}
      if test $? -ne 0
      then
        status=1
      fi
    done
    if test ${status} -eq 1
    then
      false
    fi
    ```

2. UDP

    ```bash
    status=0
    for nsc in "${NSCS[@]}"
    do
      IP_ADDRESS=$(kubectl exec ${nsc} -c cmd-nsc -n ${NAMESPACE} -- ip -4 addr show nsm-1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
      kubectl exec ${nsc} -c iperf-server -n ${NAMESPACE} -- iperf3 -sD -B ${IP_ADDRESS} -1
      docker exec rvm-tester iperf3 -i0 -t 5 -u -c ${IP_ADDRESS}
      if test $? -ne 0
      then
        status=1
      fi
    done
    if test ${status} -eq 1
    then
      false
    fi
    ```

Start iperf server on tester:

1. TCP

    ```bash
    status=0
    for nsc in "${NSCS[@]}"
    do
      docker exec rvm-tester iperf3 -sD -B 172.10.0.254 -1
      kubectl exec ${nsc} -c iperf-server -n ${NAMESPACE} -- iperf3 -i0 -t 5 -c 172.10.0.254
      if test $? -ne 0
      then
        status=1
      fi
    done
    if test ${status} -eq 1
    then
      false
    fi
    ```

2. UDP

    ```bash
    status=0
    for nsc in "${NSCS[@]}"
    do
      docker exec rvm-tester iperf3 -sD -B 172.10.0.254 -1
      kubectl exec ${NSCS[1]} -c iperf-server -n ${NAMESPACE} -- iperf3 -i0 -t 5 -u -c 172.10.0.254
      if test $? -ne 0
      then
        status=1
      fi
    done
    if test ${status} -eq 1
    then
      false
    fi
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
