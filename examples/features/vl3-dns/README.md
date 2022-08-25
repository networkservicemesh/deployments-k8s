# vL3 dns single cluster example

This example shows how is working DNS in the vl3 network.


Diagram: 

![NSM vL3 Diagram](./vl3-dns.svg "NSM vl3 DNS Scheme")


**NOTE: Forwarder and NSMmgr are not added in the diagram for the simplicity**


By this example we are using by defeault the next go-template for DNS records generating:

```go-template
{{ index .Labels \"podName\" }}.{{ .NetworkService }}
```

The vl3 dns server handles the incoming connection and uses the template to generate DNS record. 

For example, `nsc.netsvc-1` will be generated for the next conntection:`{"labels":{"podName": "nsc"}, "networkservice": "netsvc-1"}`.

The template could be changed via env variable of [cmd-nse-vl3-vpp](../../../apps/nse-vl3-vpp/): `NSM_DNS_TEMPLATES`.

## Run


1. Deploy network service, nsc and vl3 nses (See at `kustomization.yaml`):

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/vl3-dns?ref=abdc6b5dea82a906e7ece4c027526693bff25eb1
```

2. Find all nscs:

```bash
nscs=$(kubectl  get pods -l app=alpine -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}" -n ns-dns-vl3) 
[[ ! -z $nscs ]]
```

3. Ping each client by each client via DNS:

```bash
for nsc in $nscs 
do
    for pinger in $nscs
    do
        kubectl exec $pinger -n ns-dns-vl3 -- ping -c4 $nsc.my-vl3-network
    done
done
```


## Cleanup


To cleanup the example just follow the next command:

```bash
kubectl delete ns ns-dns-vl3
```