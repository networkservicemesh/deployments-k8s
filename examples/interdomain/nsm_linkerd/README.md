# NSM + Consul interdomain example over kind clusters

This example shows how Consul can be used over NSM. 


## Requires

- [Load balancer](../loadbalancer)
- [Interdomain DNS](../dns)
- [Interdomain spire](../spire)
- [Interdomain nsm](../nsm)


## Run

Install Linkerd CLI:
```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```
Verify Linkerd CLI is installed:
```bash
linkerd version
```
If not, export linkerd path to $PATH:

Install Linkerd onto the second cluster:
```bash
export KUBECONFIG=$KUBECONFIG2

linkerd check --pre
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -
linkerd check
```

Install networkservice for the second cluster::
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/5278bf09564d36b701e8434d9f1d4be912e6c266/examples/interdomain/nsm_consul/networkservice.yaml
```

Start `emojivo` networkservicemesh client for the first cluster:

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/5278bf09564d36b701e8434d9f1d4be912e6c266/examples/interdomain/nsm_consul/client/dashboard.yaml
```

Create kubernetes service for the networkservicemesh endpoint:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/5278bf09564d36b701e8434d9f1d4be912e6c266/examples/interdomain/nsm_consul/service.yaml
```

Start `auto-scale` networkservicemesh endpoint:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm_consul/nse-auto-scale?ref=5278bf09564d36b701e8434d9f1d4be912e6c266
```

Install `counting` Consul workload on the second cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/5278bf09564d36b701e8434d9f1d4be912e6c266/examples/interdomain/nsm_consul/server/counting.yaml
```

Wait for the dashboard client to be ready
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --timeout=5m --for=condition=ready pod -l app=dashboard-nsc
```

Verify connection from networkservicemesh client to the consul counting service:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pod/dashboard-nsc -c cmd-nsc -- apk add curl
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pod/dashboard-nsc -c cmd-nsc -- curl counting:9001 
```

Port forward and check connectivity from NSM+Consul by yourself!
```bash
kubectl --kubeconfig=$KUBECONFIG1 port-forward pod/dashboard-nsc 9002:9002 &
```
Now we're simulating that something went wrong and counting from the consul cluster is down.
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete deploy counting
```
Check UI and ensure that you see errors.
Now lets start counting on cluster1:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/5278bf09564d36b701e8434d9f1d4be912e6c266/examples/interdomain/nsm_consul/server/counting_nsm.yaml
```
Check UI again and ensure that the dashboard sees a new counting pod. 
Congratulations! You have made a interdomain connection between via NSM + Consul!


## Cleanup


```bash
kubectl --kubeconfig=$KUBECONFIG1 delete deployment counting
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm_consul/nse-auto-scale?ref=5278bf09564d36b701e8434d9f1d4be912e6c266
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/5278bf09564d36b701e8434d9f1d4be912e6c266/examples/interdomain/nsm_consul/client/dashboard.yaml
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/5278bf09564d36b701e8434d9f1d4be912e6c266/examples/interdomain/nsm_consul/networkservice.yaml
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete pods --all
```
```bash
consul-k8s uninstall --kubeconfig=$KUBECONFIG2 -auto-approve=true -wipe-data=true
```
