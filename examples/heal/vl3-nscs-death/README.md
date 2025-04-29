# vL3-network - NSC death

This example shows vl3-network recovery after redeploying all clients.


## Run

Deploy nsc and vl3 nses:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/vl3-nscs-death?ref=v1.14.5-rc.2
```

Wait for clients to be ready:
```bash
kubectl wait -n ns-vl3-nscs-death --for=condition=ready --timeout=1m pod -l app=nettools
```

Find all nscs:
```bash
nscs=$(kubectl  get pods -l app=nettools -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}" -n ns-vl3-nscs-death)
[[ ! -z $nscs ]]
```

Ping each client by each client:
```bash
(
for nsc in $nscs
do
    ipAddr=$(kubectl exec -n ns-vl3-nscs-death $nsc -- ifconfig nsm-1) || exit
    ipAddr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    for pinger in $nscs
    do
        echo $pinger pings $ipAddr
        kubectl exec $pinger -n ns-vl3-nscs-death -- ping -c2 -i 0.5 $ipAddr || exit
    done
done
)
```

Scale NSCs to zero:
```bash
kubectl scale -n ns-vl3-nscs-death deployment nettools --replicas=0
```
```bash
kubectl wait -n ns-vl3-nscs-death --for=delete --timeout=1m pod -l app=nettools
```

Rescale NSCs:
```bash
kubectl scale -n ns-vl3-nscs-death deployment nettools --replicas=2
```
```bash
kubectl wait -n ns-vl3-nscs-death --for=condition=ready --timeout=1m pod -l app=nettools
```

Find all new nscs and run ping:
```bash
nscs=$(kubectl  get pods -l app=nettools -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}" -n ns-vl3-nscs-death)
[[ ! -z $nscs ]]
```
```bash
(
for nsc in $nscs
do
    ipAddr=$(kubectl exec -n ns-vl3-nscs-death $nsc -- ifconfig nsm-1) || exit
    ipAddr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    for pinger in $nscs
    do
        echo $pinger pings $ipAddr
        kubectl exec $pinger -n ns-vl3-nscs-death -- ping -c2 -i 0.5 $ipAddr || exit
    done
done
)
```

## Cleanup

To cleanup the example just follow the next command:
```bash
kubectl delete ns ns-vl3-nscs-death
```
