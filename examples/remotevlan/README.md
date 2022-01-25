# NSM Remote Vlan Examples

This setup can be used to check remote vlan mechanism. Contain basic setup for NSM that includes `nsmgr`, `registry-k8s`, `admission-webhook-k8s`, `nse-remote-vlan`. The `nse-remote-vlan` belongs to the nsm-system since does not have role in data-plane connection.

## Requires

- [spire](../spire)

## Includes

- [Remote VLAN mechanism using forwarder-vpp](./rvlanvpp)

## Run

1. Create secondary bridge network and connect kind-worker nodes:

    ```bash
    docker network create bridge-2
    docker network connect bridge-2 kind-worker
    docker network connect bridge-2 kind-worker2
    ```

2. Rename the newly generated interface to eth1 in both kind-workers:

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

3. Create ns for deployments:

    ```bash
    kubectl create ns nsm-system
    ```

4. Apply NSM resources for basic tests:

    ```bash
    kubectl apply -k .
    ```

5. Wait for NSE application:

    ```bash
    kubectl -n nsm-system wait --for=condition=ready --timeout=2m pod -l app=nse-remote-vlan
    ```

6. Wait for admission-webhook-k8s:

    ```bash
    WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
    kubectl wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
    ```

## Cleanup

1. To free resources follow the next command:

    ```bash
    kubectl delete mutatingwebhookconfiguration --all
    kubectl delete ns nsm-system
    ```

2. Delete secondary network and kind-worker node connections:

    ```bash
    docker network disconnect bridge-2 kind-worker
    docker network disconnect bridge-2 kind-worker2
    docker network rm bridge-2
    docker exec kind-worker ip link del eth1
    docker exec kind-worker2 ip link del eth1
    true
    ```
