# Test automatic scale from zero

This example shows that vL3-NSEs can be created on the fly on NSC requests.
This allows effective scaling for endpoints.
The requested endpoint will be automatically spawned on the same node as NSC,
allowing the best performance for connectivity.

## Run

Create test namespace:

```bash
kubectl create ns ns-vl3-scale-from-zero
```

Deploy NSC and supplier:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/vl3-scale-from-zero?ref=1cbc57dab0c9fe6c28e53adba588ac7eba4fbec1
```

Wait for applications ready:
```bash
kubectl wait -n ns-vl3-scale-from-zero --for=condition=ready --timeout=1m pod -l app=nse-supplier-k8s
```
```bash
kubectl wait -n ns-vl3-scale-from-zero --for=condition=ready --timeout=1m pod -l app=alpine
```
```bash
kubectl wait -n ns-vl3-scale-from-zero --for=condition=ready --timeout=1m pod -l app=nse-vl3-vpp
```

Find all nscs:
```bash
nscs=$(kubectl  get pods -l app=alpine -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}" -n ns-vl3-scale-from-zero)
[[ ! -z $nscs ]]
```

Ping each client by each client:
```bash
(
for nsc in $nscs 
do
    ipAddr=$(kubectl exec -n ns-vl3-scale-from-zero $nsc -- ifconfig nsm-1) || exit
    ipAddr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    for pinger in $nscs
    do
        echo $pinger pings $ipAddr
        kubectl exec $pinger -n ns-vl3-scale-from-zero -- ping -c4 $ipAddr || exit
    done
done
)
```

Ping each vl3-nse by each client.
Note: By default ipam prefix is `172.16.0.0/16` and client prefix len is `24`. We also have two vl3 nses in this example. So we expect to have two vl3 addresses: `172.16.0.0` and `172.16.1.0` that should be accessible by each client.
```bash
(
for nsc in $nscs 
do
    echo $nsc pings nses
    kubectl exec -n ns-vl3-scale-from-zero $nsc -- ping 172.16.0.0 -c4 || exit
    kubectl exec -n ns-vl3-scale-from-zero $nsc -- ping 172.16.1.0 -c4 || exit
done
)
```

## Cleanup

Delete namespace:
```bash
kubectl delete ns ns-vl3-scale-from-zero
```
