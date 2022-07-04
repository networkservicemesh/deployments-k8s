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

Wait for proxy-alpine-nsc to be ready:
```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=3m pod proxy-alpine-nsc
kubectl --kubeconfig=$KUBECONFIG2 describe pods proxy-alpine-nsc
kubectl --kubeconfig=$KUBECONFIG2 exec -it proxy-alpine-nsc -- bash -c ls
```

Wait for static-server to be ready:
```bash
stsrv=$(kubectl get pods -l app=static-server --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=3m pod $stsrv
kubectl --kubeconfig=$KUBECONFIG2 describe pods $stsrv
```

Wait for nse-supplier to be ready:
```bash
supplier=$(kubectl get pods -l app=nse-supplier-k8s --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=3m pod $supplier
kubectl --kubeconfig=$KUBECONFIG2 describe pods $supplier
```

Wait for nse-supplier to be ready:
```bash
kubectl --kubeconfig=$KUBECONFIG2 describe pods alpine-nsc
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=10m pod alpine-nsc
```

Verify connection from networkservicemesh client to consul server:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec -it alpine-nsc -- apk add curl
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec -it alpine-nsc -- curl 172.16.1.2:8080 | grep -o "hello world"
```


## Cleanup


```bash
kubectl --kubeconfig=$KUBECONFIG2 delete deployment static-server
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete -k nse-auto-scale
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete -f client/client.yaml
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete -f networkservice.yaml
```
```bash
consul-k8s uninstall --kubeconfig=$KUBECONFIG2 -auto-approve=true -wipe-data=true
```
