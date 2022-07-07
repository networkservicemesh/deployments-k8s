# NSM + Consul interdomain example over kind clusters

This example show how Consul can be used over nsm 


## Requires

- [Load balancer](../basic_interdomain/loadbalancer)
- [Interdomain DNS](../basic_interdomain/dns)
- [Interdomain spire](../basic_interdomain/spire)
- [Interdomain nsm](../basic_interdomain/nsm)


## Run

Install Consul
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/consul-k8s
```

Install Consul for the second cluster:
```bash
consul-k8s install -config-file=helm-consul-values.yaml -set global.image=hashicorp/consul:1.12.0 -auto-approve --kubeconfig=$KUBECONFIG2
```

Install networkservice for the second cluster::
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f networkservice.yaml 
```

Start `dashboard` networkservicemesh client for the first cluster:

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f client/dashboard.yaml 
```

Create kubernetes service for the networkservicemesh endpoint:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f service.yaml 
```

Start `auto-scale` networkservicemesh endpoint:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k nse-auto-scale
```

Install `counting` Consul workload on the second cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f server/counting.yaml
```

Wait for the dashboard client to be ready
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --timeout=5m --for=condition=ready pod -l app=dashboard-nsc
```

Verify connection from networkservicemesh client to the consul counting service:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec -it dashboard -- apk add curl
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec -it dashboard -- curl counting:9001 
```

Port forward and check connectivity from NSM+Consul by yourself!
```bash
kubectl --kubeconfig=$KUBECONFIG1 port-forward dashboard 9002:9002
```
Now we're simulating that someting went wrong and counting from the consul cluster is down.
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete deploy counting
```
Port forward and check that you see errors:
```bash
kubectl --kubeconfig=$KUBECONFIG1 port-forward dashboard 9002:9002
```
Now lets start counting on cluster1:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f server/counting_nsm.yaml
```
Port forward and check that you don't have errors:
```bash
kubectl --kubeconfig=$KUBECONFIG2 port-forward dashboard 9002:9002
```
Congratulations! You have made a interdomain connection between via NSM + Consul!


## Cleanup


```bash
kubectl --kubeconfig=$KUBECONFIG2 delete deployment counting
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete -k nse-auto-scale
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete -f client/dashboard.yaml
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete -f networkservice.yaml
```
```bash
consul-k8s uninstall --kubeconfig=$KUBECONFIG2 -auto-approve=true -wipe-data=true
```
