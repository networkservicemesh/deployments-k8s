# NSM Remote Vlan Examples

This setup can be used to check remote vlan mechanism with both  VPP forwarder. Contain basic setup for NSM that includes `nsmgr`, `registry-k8s`, `forwarder-vpp`, `admission-webhook-k8s`, `nse-remote-vlan`. The `nse-remote-vlan` belongs to the nsm-system since does not have role in data-plane connection.

## Requires

- [spire](../spire/single_cluster)

## Run

Create secondary bridge network and connect kind-worker nodes:

```bash
docker network create bridge-2
docker network connect bridge-2 kind-worker
docker network connect bridge-2 kind-worker2
```

Rename the newly generated interface to ext_net1 in both kind-workers:

```bash
MACS=($(docker inspect --format='{{range .Containers}}{{.MacAddress}}{{"\n"}}{{end}}' bridge-2))
ifw1=$(docker exec kind-worker ip -o link | grep ${MACS[@]/#/-e } | cut -f1 -d"@" | cut -f2 -d" ")
ifw2=$(docker exec kind-worker2 ip -o link | grep ${MACS[@]/#/-e } | cut -f1 -d"@" | cut -f2 -d" ")

(docker exec kind-worker ip link set $ifw1 down &&
docker exec kind-worker ip link set $ifw1 name ext_net1 &&
docker exec kind-worker ip link set dev ext_net1 mtu 1450 &&
docker exec kind-worker ip link set ext_net1 up &&
docker exec kind-worker2 ip link set $ifw2 down &&
docker exec kind-worker2 ip link set $ifw2 name ext_net1 &&
docker exec kind-worker2 ip link set dev ext_net1 mtu 1450 &&
docker exec kind-worker2 ip link set ext_net1 up)
```

Create ns for deployments:

Apply NSM resources for basic tests:

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/remotevlan_vpp?ref=dc5d993d0aaf02d20e142aacf180cf74b2641d6f
```

Wait for NSE application:

```bash
kubectl -n nsm-system wait --for=condition=ready --timeout=2m pod -l app=nse-remote-vlan
```

Wait for admission-webhook-k8s:

```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```

Wait for forwarder-vpp:

```bash
kubectl -n nsm-system wait --for=condition=ready --timeout=2m pod -l app=forwarder-vpp
```

## Includes

- [Kernel2RVlanInternal](../use-cases/Kernel2RVlanInternal)
- [Kernel2RVlanBreakout](../use-cases/Kernel2RVlanBreakout)
- [Kernel2RVlanMultiNS](../use-cases/Kernel2RVlanMultiNS)

## Cleanup

To free resources follow the next command:

```bash
kubectl delete mutatingwebhookconfiguration nsm-mutating-webhook
kubectl delete ns nsm-system
```

Delete secondary network and kind-worker node connections:

```bash
docker network disconnect bridge-2 kind-worker
docker network disconnect bridge-2 kind-worker2
docker network rm bridge-2
docker exec kind-worker ip link del ext_net1
docker exec kind-worker2 ip link del ext_net1
true
```
