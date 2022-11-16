# vL3 single cluster example

This example shows how could be configured vL3 network via NSM.


Diagram: 

![NSM vL3 Diagram](./diagram.png "NSM Authorize Scheme")


**NOTE: Forwarder and NSMmgr are missed in the diagram for the simplicity**

## Run


Create ns to deploy nse and nsc:
```bash
kubectl create ns ns-vl3-nse-death
```

Deploy nsc and vl3 nses:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/vl3-nse-death?ref=45aadfc1b5ec901639a850e76871861b731de0ff
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
for nsc in $nscs 
do
    ipAddr=$(kubectl exec -n ns-vl3-nse-death $nsc -- ifconfig nsm-1)
    ipAddr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    for pinger in $nscs
    do
        echo $pinger pings $ipAddr
        kubectl exec $pinger -n ns-vl3-nse-death -- ping -c4 $ipAddr
    done
done
```

```bash
NSE=($(kubectl get pods -l app=nse-vl3-vpp -n ns-vl3-nse-death --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')[0])
```

```bash
kubectl delete pod -n ns-vl3-nse-death ${NSE}
```

```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-vl3-vpp -n ns-vl3-nse-death
```

```bash
for nsc in $nscs 
do
    ipAddr=$(kubectl exec -n ns-vl3-nse-death $nsc -- ifconfig nsm-1)
    ipAddr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    for pinger in $nscs
    do
        echo $pinger pings $ipAddr
        kubectl exec $pinger -n ns-vl3-nse-death -- ping -c4 $ipAddr
    done
done
```

## Cleanup


To cleanup the example just follow the next command:

```bash
kubectl delete ns ns-vl3-nse-death
```