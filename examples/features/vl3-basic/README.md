# vL3 single cluster example

This example shows how could be configured vL3 network via NSM.


Diagram: 

![NSM vL3 Diagram](./diagram.png "NSM Authorize Scheme")


**NOTE: Forwarder and NSMmgr are missed in the diagram for the simplicity**


## Run

Create ns to deploy nse and nsc:
```bash
kubectl create ns ns-vl3
```

Deploy network service, nsc and vl3 nses (See at `kustomization.yaml`):
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/vl3-basic?ref=4f7fd73ac0f75e0f9492f2a65a6b393a4b708de9
```

Wait for clients to be ready:
```bash
kubectl wait --for=condition=ready --timeout=2m pod -l app=nsc-kernel -n ns-vl3
```

Find all nscs:
```bash
nscs=$(kubectl  get pods -l app=nsc-kernel -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}" -n ns-vl3)
[[ ! -z $nscs ]]
```

Ping each client by each client:
```bash
for nsc in $nscs 
do
    ipAddr=$(kubectl exec -n ns-vl3 $nsc -- ifconfig nsm-1)
    ipAddr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    for pinger in $nscs
    do
        echo $pinger pings $ipAddr
        kubectl exec $pinger -n ns-vl3 -- ping -c4 $ipAddr
    done
done
```

Ping each vl3-nse by each client.
Note: By default ipam prefix is `172.16.0.0/16` and client prefix len is `24`. We also have two vl3 nses in this example. So we expect to have two vl3 addresses: `172.16.0.0` and `172.16.1.0` that should be accessible by each client.
```bash
for nsc in $nscs 
do
    echo $nsc pings nses
    kubectl exec -n ns-vl3 $nsc -- ping 172.16.0.0 -c4
    kubectl exec -n ns-vl3 $nsc -- ping 172.16.1.0 -c4
done
```

## Cleanup

To cleanup the example just follow the next command:
```bash
kubectl delete ns ns-vl3
```
