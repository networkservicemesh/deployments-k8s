# vL3-network - NSC death

This example shows vl3-network recovery after redeploying all clients.


## Run

Create ns to deploy nse and nsc:
```bash
kubectl create ns ns-vl3-nscs-death
```

Deploy nsc and vl3 nses:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/vl3-nscs-death?ref=185694dea28c41ccaa37331a2293de526e98823f
```

Wait for clients to be ready:
```bash
kubectl wait -n ns-vl3-nscs-death --for=condition=ready --timeout=1m pod -l app=alpine
```

Find all nscs:
```bash
nscs=$(kubectl  get pods -l app=alpine -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}" -n ns-vl3-nscs-death)
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
kubectl scale -n ns-vl3-nscs-death deployment alpine --replicas=0
```
```bash
kubectl wait -n ns-vl3-nscs-death --for=delete --timeout=1m pod -l app=alpine
```

Rescale NSCs:
```bash
kubectl scale -n ns-vl3-nscs-death deployment alpine --replicas=2
```
```bash
kubectl wait -n ns-vl3-nscs-death --for=condition=ready --timeout=1m pod -l app=alpine
```

Find all new nscs and run ping:
```bash
nscs=$(kubectl  get pods -l app=alpine -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}" -n ns-vl3-nscs-death)
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
