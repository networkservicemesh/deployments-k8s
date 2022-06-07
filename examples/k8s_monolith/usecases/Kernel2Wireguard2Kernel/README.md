# Test kernel to wireguard to kernel connection

NSC and docker-NSE are using the `kernel` local mechanism.
`Wireguard` is used as remote mechanism.

## Requires

Make sure that you have completed steps from [k8s_monolith](../../)

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/7758662e8a91c411ed8740e9f76c3c921d87d321/examples/k8s_monolith/usecases/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

Create kustomization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE}

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-kernel?ref=7758662e8a91c411ed8740e9f76c3c921d87d321

patchesStrategicMerge:
- patch-nsc.yaml
EOF
```

Create Client:
```bash
cat > patch-nsc.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nsc-kernel
spec:
  replicas: 2
  template:
    spec:
      containers:
        - name: nsc
          env:
            - name: NSM_NETWORK_SERVICES
              value: kernel://docker-vl3/nsm-1
EOF
```

Deploy NSC:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel -n ${NAMESPACE}
```

Find all NSCs:
```bash
nscs=$(kubectl  get pods -l app=nsc-kernel -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}" -n ${NAMESPACE})
[[ ! -z $nscs ]]
```

Ping each client by each client:
```bash
for nsc in $nscs
do
    ipAddr=$(kubectl exec -n ${NAMESPACE} $nsc -- ifconfig nsm-1)
    ipAddr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    for pinger in $nscs
    do
        echo $pinger pings $ipAddr
        kubectl exec $pinger -n ${NAMESPACE} -- ping -c4 $ipAddr
    done
done
```

Ping docker-nse by each client:
```bash
for nsc in $nscs
do
    echo $nsc pings docker-nse
    kubectl exec -n ${NAMESPACE} $nsc -- ping 169.254.0.1 -c4
done
```

Ping each client by docker-nse:
```bash
for nsc in $nscs
do
    ipAddr=$(kubectl exec -n ${NAMESPACE} $nsc -- ifconfig nsm-1)
    ipAddr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    docker exec nse-simple-vl3-docker ping -c4 $ipAddr
done
```

## Cleanup

Delete ns:

```bash
kubectl delete ns ${NAMESPACE}
```
