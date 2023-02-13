# vL3-network - NSE death

This example shows vl3-network recovery after one of the vl3-nse death.


## Run

Deploy nsc and vl3 nses:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/vl3-nse-death?ref=c3b9a35b310f7132f785d6f3dea50d2a4570282c
```

Wait for clients to be ready:
```bash
kubectl wait -n ns-vl3-nse-death --for=condition=ready --timeout=1m pod -l app=alpine
```

Find all nscs:
```bash
nscs=$(kubectl  get pods -l app=alpine -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}" -n ns-vl3-nse-death) 
[[ ! -z $nscs ]]
```

Ping each client by each client:
```bash
(
for nsc in $nscs 
do
    ipAddr=$(kubectl exec -n ns-vl3-nse-death $nsc -- ifconfig nsm-1) || exit
    ipAddr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    for pinger in $nscs
    do
        echo $pinger pings $ipAddr
        kubectl exec $pinger -n ns-vl3-nse-death -- ping -c2 -i 0.5 $ipAddr || exit
    done
done
)
```

Get one of the vl3-NSE pod and delete it:
```bash
NSE=($(kubectl get pods -l app=nse-vl3-vpp -n ns-vl3-nse-death --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')[0])
```
```bash
kubectl delete pod -n ns-vl3-nse-death ${NSE}
```

Wait for a new one to be ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-vl3-vpp -n ns-vl3-nse-death
```

Ping each client by each client:
```bash
(
for nsc in $nscs 
do
    ipAddr=$(kubectl exec -n ns-vl3-nse-death $nsc -- ifconfig nsm-1) || exit
    ipAddr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    for pinger in $nscs
    do
        echo $pinger pings $ipAddr
        kubectl exec $pinger -n ns-vl3-nse-death -- ping -c2 -i 0.5 $ipAddr || exit
    done
done
)
```

## Cleanup

To cleanup the example just follow the next command:
```bash
kubectl delete ns ns-vl3-nse-death
```
