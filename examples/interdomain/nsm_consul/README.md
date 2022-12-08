# NSM + Consul interdomain example over kind clusters

This example shows how Consul can be used over NSM. 


## Requires

- [Load balancer](../loadbalancer)
- [Interdomain DNS](../dns)
- Interdomain spire
    - [Spire on first cluster](../../spire/cluster1)
    - [Spire on second cluster](../../spire/cluster2)
    - [Spiffe Federation](../spiffe_federation)
- [Interdomain nsm](../nsm)


## Run

Install [Consul](https://www.consul.io/docs/k8s/installation/install-cli)
```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install consul-k8s=0.48.0-1
consul-k8s version
```

Install Consul for the second cluster:
```bash
consul-k8s install -config-file=helm-consul-values.yaml -set global.image=hashicorp/consul:1.12.0 -auto-approve --kubeconfig=$KUBECONFIG2
```

Install networkservice for the second cluster::
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/d71598ccc84f00009641b1abc542e819bf145ed1/examples/interdomain/nsm_consul/networkservice.yaml
```

Start `dashboard` networkservicemesh client for the first cluster:

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/d71598ccc84f00009641b1abc542e819bf145ed1/examples/interdomain/nsm_consul/client/dashboard.yaml
```

Create kubernetes service for the networkservicemesh endpoint:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/d71598ccc84f00009641b1abc542e819bf145ed1/examples/interdomain/nsm_consul/service.yaml
```

Start `auto-scale` networkservicemesh endpoint:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm_consul/nse-auto-scale?ref=d71598ccc84f00009641b1abc542e819bf145ed1
```

Install `counting` Consul workload on the second cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/d71598ccc84f00009641b1abc542e819bf145ed1/examples/interdomain/nsm_consul/server/counting.yaml
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
kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/d71598ccc84f00009641b1abc542e819bf145ed1/examples/interdomain/nsm_consul/server/counting_nsm.yaml
```
Wait for new counting pod to be ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --timeout=5m --for=condition=ready pod -l app=counting
```

Check UI again and ensure that the dashboard sees a new counting pod. 
Congratulations! You have made a interdomain connection between via NSM + Consul!

Verify connection from networkservicemesh client to the new counting service:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pod/dashboard-nsc -c cmd-nsc -- curl counting:9001 
```


## Cleanup

```bash
pkill -f "port-forward"
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete deployment counting
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm_consul/nse-auto-scale?ref=d71598ccc84f00009641b1abc542e819bf145ed1
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/d71598ccc84f00009641b1abc542e819bf145ed1/examples/interdomain/nsm_consul/client/dashboard.yaml
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/d71598ccc84f00009641b1abc542e819bf145ed1/examples/interdomain/nsm_consul/networkservice.yaml
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete pods --all
```
```bash
consul-k8s uninstall --kubeconfig=$KUBECONFIG2 -auto-approve=true -wipe-data=true
```
