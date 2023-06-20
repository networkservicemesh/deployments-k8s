# Test kernel to IP to kernel connection

NSC and docker-NSE are using the `kernel` local mechanism.
`Wireguard` is used as remote mechanism.

## Requires

Make sure that you have completed steps from [external NSE](../../)

## Run

Deploy NSC:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/k8s_monolith/external_nse/usecases/Kernel2IP2Kernel?ref=f530d9ca349d319d0b2660f3cad85b14db0d5b89
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-kernel2ip2kernel-monolith-nse
```

Find all NSCs:
```bash
nscs=$(kubectl  get pods -l app=alpine -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}" -n ns-kernel2ip2kernel-monolith-nse)
[[ ! -z $nscs ]]
```

Ping each client by each client:
```bash
(
for nsc in $nscs
do
    ipAddr=$(kubectl exec -n ns-kernel2ip2kernel-monolith-nse $nsc -- ifconfig nsm-1) || exit
    ipAddr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    for pinger in $nscs
    do
        echo $pinger pings $ipAddr
        kubectl exec $pinger -n ns-kernel2ip2kernel-monolith-nse -- ping -c2 -i 0.5 $ipAddr || exit
    done
done
)
```

Ping docker-nse by each client:
```bash
(
for nsc in $nscs
do
    echo $nsc pings docker-nse
    kubectl exec -n ns-kernel2ip2kernel-monolith-nse $nsc -- ping 169.254.0.1 -c2 -i 0.5  || exit
done
)
```

Ping each client by docker-nse:
```bash
(
for nsc in $nscs
do
    ipAddr=$(kubectl exec -n ns-kernel2ip2kernel-monolith-nse $nsc -- ifconfig nsm-1) || exit
    ipAddr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    docker exec nse-simple-vl3-docker ping -c2 -i 0.5 $ipAddr || exit
done
)
```

## Cleanup

Delete ns:

```bash
kubectl delete ns ns-kernel2ip2kernel-monolith-nse
```
