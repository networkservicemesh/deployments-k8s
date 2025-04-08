# vL3-network - Dataplane interruption

This example shows that vl3 network recovers itself after dataplane interruption


## Run

Deploy clients and vl3 nses:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/vl3-dataplane-interrupt?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Wait for clients to be ready:
```bash
kubectl wait -n ns-vl3-dataplane-interrupt --for=condition=ready --timeout=1m pod -l app=nettools
```

Find all clients:
```bash
nscs=$(kubectl  get pods -l app=nettools -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}" -n ns-vl3-dataplane-interrupt)
[[ ! -z $nscs ]]
```

Check connections between clients:
```bash
(
for nsc in $nscs 
do
    ipAddr=$(kubectl exec -n ns-vl3-dataplane-interrupt $nsc -c nettools -- ifconfig nsm-1) || exit
    ipAddr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    for pinger in $nscs
    do
        echo $pinger pings $ipAddr
        kubectl exec $pinger -n ns-vl3-dataplane-interrupt -- ping -c2 -i 0.5 $ipAddr || exit
    done
done
)
```

Check connections between clients and vl3 endpoints:
```bash
(
for nsc in $nscs 
do
    echo $nsc pings nses
    kubectl exec -n ns-vl3-dataplane-interrupt $nsc -- ping -c2 -i 0.5 172.16.0.0 || exit
    kubectl exec -n ns-vl3-dataplane-interrupt $nsc -- ping -c2 -i 0.5 172.16.1.0 || exit
done
)
```

Get vl3 NSEs:
```bash
nses=$(kubectl get pods -l app=nse-vl3-vpp -n ns-vl3-dataplane-interrupt --template '{{range .items}}{{.metadata.name}} {{end}}')
NSE1=$(echo $nses | cut -d " " -f 1)
NSE2=$(echo $nses | cut -d " " -f 2)
```

Disable all memif interfaces on the first vl3 NSE:
```bash
ifaces=$(kubectl exec -n ns-vl3-dataplane-interrupt $NSE1 -- vppctl show int | grep memif | awk '{print $1}' | tr '\n' ' ')
for if in $ifaces
do
    kubectl exec -n ns-vl3-dataplane-interrupt $NSE1 -- vppctl set interface state $if down
done
```

Check connections between clients:
```bash
(
for nsc in $nscs 
do
    ipAddr=$(kubectl exec -n ns-vl3-dataplane-interrupt $nsc -- ifconfig nsm-1) || exit
    ipAddr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    for pinger in $nscs
    do
        echo $pinger pings $ipAddr
        kubectl exec $pinger -n ns-vl3-dataplane-interrupt -- ping -c2 -i 0.5 $ipAddr || exit
    done
done
)
```

Check connections between clients and vl3 endpoints:
```bash
(
for nsc in $nscs 
do
    echo $nsc pings nses
    kubectl exec -n ns-vl3-dataplane-interrupt $nsc -- ping -c2 -i 0.5 172.16.0.0 || exit
    kubectl exec -n ns-vl3-dataplane-interrupt $nsc -- ping -c2 -i 0.5 172.16.1.0 || exit
done
)
```

Disable all memif interfaces on the second vl3 NSE:
```bash
ifaces=$(kubectl exec -n ns-vl3-dataplane-interrupt $NSE2 -- vppctl show int | grep memif | awk '{print $1}' | tr '\n' ' ')
for if in $ifaces
do
    kubectl exec -n ns-vl3-dataplane-interrupt $NSE2 -- vppctl set interface state $if down
done
```

Check connections between clients:
```bash
(
for nsc in $nscs 
do
    ipAddr=$(kubectl exec -n  ns-vl3-dataplane-interrupt $nsc -- ifconfig nsm-1) || exit
    ipAddr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    for pinger in $nscs
    do
        echo $pinger pings $ipAddr
        kubectl exec $pinger -n ns-vl3-dataplane-interrupt -- ping -c2 -i 0.5 $ipAddr || exit
    done
done
)
```

Check connections between clients and vl3 endpoints:
```bash
(
for nsc in $nscs 
do
    echo $nsc pings nses
    kubectl exec -n ns-vl3-dataplane-interrupt $nsc -- ping -c2 -i 0.5 172.16.0.0 || exit
    kubectl exec -n ns-vl3-dataplane-interrupt $nsc -- ping -c2 -i 0.5 172.16.1.0 || exit
done
)
```

## Cleanup

```bash
kubectl delete ns ns-vl3-dataplane-interrupt
```
