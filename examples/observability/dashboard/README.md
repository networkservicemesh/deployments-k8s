# Network Service Mesh Dashboard

Provides UI to visualize the Network Service Mesh topology in various aspects, displaying the state of components and operating statistics

The dashboard consists of two parts:
- [dashboard-backend](https://github.com/networkservicemesh/cmd-dashboard-backend)
- [dashboard-ui](https://github.com/networkservicemesh/cmd-dashboard-ui)

## Requires

- [Basic NSM setup](../../basic/)

## Run

To run the dashboard in the cluster, execute the command:

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/apps/dashboard?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Wait for the dashboard pod to start:

```bash
kubectl wait --for=condition=ready pod -l app=dashboard --timeout=5m -n nsm-system
```

Port-forward dashboard-backend REST-API:

```bash
nohup kubectl port-forward -n nsm-system service/dashboard-backend 3001:3001 &
```

Port-forward dashboard-ui service:

```bash
nohup kubectl port-forward -n nsm-system service/dashboard-ui 3000:3000 &
```

The dashboard UI should be available in the browser by:

    http://localhost:3000

The dashboard backend functionality can be checked using any of the following ways:

- In the browser: `http://localhost:3001/nodes`
- Through the command line outside the cluster: `curl -X GET http://localhost:3001/nodes`
- Through the command line inside the cluster: `curl -X GET http://dashboard-backend.nsm-system.svc.cluster.local/nodes`

### Polling interval

The dashboard pod deployment file `deployments-k8s/apps/dashboard/dashboard-pod.yaml` contains the `POLLING_INTERVAL_SECONDS` env variable, which determines the frequency of updating the dashboard info in seconds (integer). The default value is 1 second. This value can be increased before deployment if such polling rate is not required.

## Cleanup:

To remove the dashboard from the cluster, execute the command:

```bash
pkill -f "kubectl port-forward -n nsm-system service/dashboard-backend 3001:3001"
pkill -f "kubectl port-forward -n nsm-system service/dashboard-ui 3000:3000"
kubectl delete service/dashboard-ui service/dashboard-backend pod/dashboard -n=nsm-system
```
