# NSM + Consul interdomain example over kind clusters

This example show how can be used nsm over 

![NSM  interdomain Scheme](./NSM+Istio_Datapath.svg "NSM Basic floating interdomain Scheme")


## Requires

- [Load balancer](./loadbalancer)
- [Interdomain DNS](./dns)
- [Interdomain spire](./spire)
- [Interdomain nsm](./nsm)


## Run

Install Consul for the second cluster:
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/consul-k8s
consul-k8s install -config-file=helm-consul-values.yaml -set global.image=hashicorp/consul:1.12.0 --kubeconfig=$KUBECONFIG2
```

### Verify NSM+CONSUL

Install networkservice for the second cluster::
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f networkservice.yaml
```

Start `alpine` networkservicemesh client for the first cluster:

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f client/client.yaml
```

Create kubernetes service for the networkservicemesh endpoint:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f service.yaml 
```

Start `auto-scale` networkservicemesh endpoint:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k nse-auto-scale 
```

Install `static-server` Consul workload on the second cluster:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f server/static-server.yaml 
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
kubectl --kubeconfig=$KUBECONFIG2 delete -k nse-auto-scale 
kubectl --kubeconfig=$KUBECONFIG1 delete -f client/client.yaml
kubectl --kubeconfig=$KUBECONFIG2 delete -f networkservice.yaml
consul-k8s uninstall --kubeconfig=$KUBECONFIG2 -auto-approve=true -wipe-data=true
kubectl --kubeconfig=$KUBECONFIG2 delete pods --all
kind delete clusters cluster-1 cluster-2
```
