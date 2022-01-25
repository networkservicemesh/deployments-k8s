# NSM Remote Vlan Examples

This setup can be used to check remote vlan mechanism with both OVS and VPP forwarder. Contain basic setup for NSM that includes `nsmgr`, `registry-k8s`, `admission-webhook-k8s`, `nse-remote-vlan`. The `nse-remote-vlan` belongs to the nsm-system since does not have role in data-plane connection.

## Requires

- [spire](../spire)

## Includes

- [Remote VLAN mechanism using forwarder-ovs](./rvlanovs)
- [Remote VLAN mechanism using forwarder-vpp](./rvlanvpp)

## Run

Create secondary bridge network and connect kind-worker nodes:

```bash
docker network create bridge-2
docker network connect bridge-2 kind-worker
docker network connect bridge-2 kind-worker2
```

Rename the newly generated interface to eth1 in both kind-workers:

```bash
ifw1=$(echo $(docker exec kind-worker ip link | tail -2 | head -1) | cut -f1 -d"@" | cut -f2 -d" ")
docker exec kind-worker ip link set $ifw1 down
docker exec kind-worker ip link set $ifw1 name eth1
docker exec kind-worker ip link set eth1 up
ifw2=$(echo $(docker exec kind-worker2 ip link | tail -2 | head -1) | cut -f1 -d"@" | cut -f2 -d" ")
docker exec kind-worker2 ip link set $ifw2 down
docker exec kind-worker2 ip link set $ifw2 name eth1
docker exec kind-worker2 ip link set eth1 up
```

Create ns for deployments:

```bash
kubectl create ns nsm-system
```

Create NSE patch:

```bash
cat > patch-nse.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
    name: nse-remote-vlan
spec:
  template:
    spec:
      containers:
        - name: nse
          env:
          - name: NSM_CONNECT_TO
            value: "registry:5002"
          - name: NSM_SERVICES
            value: "finance-bridge { vlan: 100; via: gw1}"
          - name: NSM_CIDR_PREFIX
            value: "172.10.0.0/24"
          - name: NSM_IPV6_PREFIX
            value: "100:200::/64"
EOF
```

Apply NSM resources for basic tests:

```bash
kubectl apply -k .
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

## Cleanup

To free resources follow the next command:

```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl delete mutatingwebhookconfiguration ${WH}
kubectl delete ns nsm-system
```

Delete secondary network and kind-worker node connections:

```bash
docker network disconnect bridge-2 kind-worker
docker network disconnect bridge-2 kind-worker2
docker network rm bridge-2
docker exec kind-worker ip link del eth1
docker exec kind-worker2 ip link del eth1
true
```
