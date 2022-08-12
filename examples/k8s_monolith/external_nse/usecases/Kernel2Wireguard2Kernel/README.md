# Test kernel to wireguard to kernel connection

NSC and docker-NSE are using the `kernel` local mechanism.
`Wireguard` is used as remote mechanism.

## Requires

Make sure that you have completed steps from [external NSE](../../)

## Run

Create test namespace:
```bash
kubectl create ns ns-kernel2wireguard2kernel-monolith-nse
```

Create kustomization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ns-kernel2wireguard2kernel-monolith-nse

resources:
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/9dad8f1e41c2b3a8e456e64884f55cc9d96e791d/examples/k8s_monolith/external_nse/usecases/Kernel2Wireguard2Kernel/netsvc.yaml

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-kernel?ref=b3b9066d54b23eee85de6a5b1578c7b49065fb89

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
              value: kernel://kernel2wireguard2kernel-monolith-nse/nsm-1
EOF
```

Deploy NSC:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel -n ns-kernel2wireguard2kernel-monolith-nse
```

Find all NSCs:
```bash
nscs=$(kubectl  get pods -l app=nsc-kernel -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}" -n ns-kernel2wireguard2kernel-monolith-nse)
[[ ! -z $nscs ]]
```

Ping each client by each client:
```bash
for nsc in $nscs
do
    ipAddr=$(kubectl exec -n ns-kernel2wireguard2kernel-monolith-nse $nsc -- ifconfig nsm-1)
    ipAddr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    for pinger in $nscs
    do
        echo $pinger pings $ipAddr
        kubectl exec $pinger -n ns-kernel2wireguard2kernel-monolith-nse -- ping -c4 $ipAddr
    done
done
```

Ping docker-nse by each client:
```bash
for nsc in $nscs
do
    echo $nsc pings docker-nse
    kubectl exec -n ns-kernel2wireguard2kernel-monolith-nse $nsc -- ping 169.254.0.1 -c4
done
```

Ping each client by docker-nse:
```bash
for nsc in $nscs
do
    ipAddr=$(kubectl exec -n ns-kernel2wireguard2kernel-monolith-nse $nsc -- ifconfig nsm-1)
    ipAddr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    docker exec nse-simple-vl3-docker ping -c4 $ipAddr
done
```

## Cleanup

Delete ns:

```bash
kubectl delete ns ns-kernel2wireguard2kernel-monolith-nse
```
