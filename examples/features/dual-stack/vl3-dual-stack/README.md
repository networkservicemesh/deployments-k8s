# vL3 dual stack example

This example shows how could be configured vL3 dual stack network via NSM.

Diagram: 

![NSM vL3 dual stack Diagram](./vl3-dual-stack.png "NSM Authorize Scheme")

**NOTE: Forwarder and NSMmgr are missed in the diagram for the simplicity**


## Run

Deploy network service, nsc and vl3 nses (See at `kustomization.yaml`):
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/dual-stack/vl3-dual-stack?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/dual-stack/vl3-dual-stack/ipam-ipv6?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Wait for clients to be ready:
```bash
kubectl wait --for=condition=ready --timeout=2m pod -l app=alpine -n ns-vl3-dual-stack
```

Find all nscs:
```bash
nscs=$(kubectl get pods -l app=alpine -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}" -n ns-vl3-dual-stack)
[[ ! -z $nscs ]]
```

Ping each client by each client:
```bash
(
for nsc in $nscs
do
    ipAddr=$(kubectl exec -n ns-vl3-dual-stack $nsc -- ifconfig nsm-1) || exit
    ipv4Addr=$(echo $ipAddr | grep -Eo 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 11-)
    ipv6Addr=$(echo $ipAddr | grep -Eo 'inet6 addr: 2001:.*' | cut -d ' ' -f 3 | cut -d '/' -f 1)
    for pinger in $nscs
    do
        if [ "$nsc" != "$pinger" ]; then
            echo $pinger pings $ipv4Addr
            kubectl exec $pinger -n ns-vl3-dual-stack -- ping -c2 -i 0.5 $ipv4Addr || exit
            echo $pinger pings $ipv6Addr
            kubectl exec $pinger -n ns-vl3-dual-stack -- ping6 -c2 -i 0.5 $ipv6Addr || exit
        fi
    done
done
)
```

Ping each vl3-nse by each client.
Note: By default ipam prefixes are `172.16.0.0/16` and `2001:db8::/64` and corresponding client prefix len-s are `24` and `112`. We also have two vl3 nses in this example. So we expect to have two ipv4 vl3 addresses: `172.16.0.0` and `172.16.1.0` and two ipv6 vl3 addresses: `2001:db8::` and `2001:db8::1:0` that should be accessible by each client.
```bash
(
for nsc in $nscs
do
    echo $nsc pings nses
    kubectl exec -n ns-vl3-dual-stack $nsc -- ping 172.16.0.0 -c2 -i 0.5 || exit
    kubectl exec -n ns-vl3-dual-stack $nsc -- ping 172.16.1.0 -c2 -i 0.5 || exit
    kubectl exec -n ns-vl3-dual-stack $nsc -- ping6 2001:db8:: -c2 -i 0.5 || exit
    kubectl exec -n ns-vl3-dual-stack $nsc -- ping6 2001:db8::1:0 -c2 -i 0.5 || exit
done
)
```

Find all nses:
```bash
nses=$(kubectl  get pods -l app=nse-vl3-vpp -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}" -n ns-vl3-dual-stack)
[[ ! -z $nses ]]
```

Ping vl3-nse by each vl3-nse.
```bash
(
for nse in $nses
do
    echo $nse pings nses
    kubectl exec -n ns-vl3-dual-stack $nse -- ping 172.16.0.0 -c2 -i 0.5 || exit
    kubectl exec -n ns-vl3-dual-stack $nse -- ping 172.16.1.0 -c2 -i 0.5 || exit
    kubectl exec -n ns-vl3-dual-stack $nse -- ping6 2001:db8:: -c2 -i 0.5 || exit
    kubectl exec -n ns-vl3-dual-stack $nse -- ping6 2001:db8::1:0 -c2 -i 0.5 || exit
done
)
```

## Cleanup

To cleanup the example just follow the next command:
```bash
kubectl delete ns ns-vl3-dual-stack
```
