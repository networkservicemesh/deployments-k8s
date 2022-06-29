# NSM + Consul interdomain example over kind clusters

This example show how Consul can be used over nsm 


## Requires

- [Load balancer](../nsm_istio/loadbalancer)
- [Interdomain DNS](../nsm_istio/dns)
- [Interdomain spire](../nsm_istio/spire)
- [Interdomain nsm](../nsm_istio/nsm)


## Run

Install Consul
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/consul-k8s
```

Install Consul for the second cluster:
```bash
consul-k8s install -config-file=https://github.com/networkservicemesh/deployments-k8s/examples/nsm_consul/helm-consul-values.yaml?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a -set global.image=hashicorp/consul:1.12.0 --kubeconfig=$KUBECONFIG2
```

### Verify NSM+CONSUL

Install networkservice for the second cluster::
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f https://github.com/networkservicemesh/deployments-k8s/examples/nsm_consul/networkservice.yaml?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a 
```

Start `alpine` networkservicemesh client for the first cluster:

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f https://github.com/networkservicemesh/deployments-k8s/examples/nsm_consul/client/client.yaml?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a 
```

Create kubernetes service for the networkservicemesh endpoint:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f https://github.com/networkservicemesh/deployments-k8s/examples/nsm_consul/service.yaml?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a 
```

Start `auto-scale` networkservicemesh endpoint:
```bash

kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/nsm_consul/nse-auto-scale?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a
```

Install `static-server` Consul workload on the second cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f https://github.com/networkservicemesh/deployments-k8s/examples/nsm_consul/server/static-server.yaml?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a  
```

Verify connection from networkservicemesh client to consul server:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec -it alpine-nsc -- apk add curl
kubectl --kubeconfig=$KUBECONFIG1 exec -it alpine-nsc -- curl 172.16.1.2:8080
```

You should see "hello world" answer.

## Cleanup


```bash
kubectl --kubeconfig=$KUBECONFIG2 delete deployment static-server
kubectl --kubeconfig=$KUBECONFIG2 delete -k https://github.com/networkservicemesh/deployments-k8s/examples/nsm_consul/nse-auto-scale?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a 
kubectl --kubeconfig=$KUBECONFIG1 delete -f client/client.yaml
kubectl --kubeconfig=$KUBECONFIG2 delete -f networkservice.yaml
consul-k8s uninstall --kubeconfig=$KUBECONFIG2 -auto-approve=true -wipe-data=true
kubectl --kubeconfig=$KUBECONFIG2 delete pods --all
kind delete clusters cluster-1 cluster-2
```
