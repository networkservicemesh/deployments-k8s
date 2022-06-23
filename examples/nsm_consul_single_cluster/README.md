# NSM + Istio interdomain example over kind cluster

## Setup Cluster

### KIND
Setup

```bash
go install sigs.k8s.io/kind@v0.13.0 

kind create cluster --config kind-cluster-config.yaml
```


## SPIRE & NSM

Use instructions from [Basic](../basic/README.md)


## CONSUL

Install Consul for a cluster:
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/consul-k8s
consul-k8s install -config-file=helm-consul-values.yaml -set global.image=hashicorp/consul:1.12.0
```

### Verify NSM+CONSUL

Install networkservice:
```bash
kubectl apply -f networkservice.yaml
```

Start `alpine` networkservicemesh client:

```bash
kubectl apply -f client/client.yaml
```

Create kubernetes service for networkservicemesh endpoint:
```bash
kubectl apply -f service.yaml 
```

Start `auto-scale` networkservicemesh endpoint:
```bash
kubectl apply -k nse-auto-scale 
```

Install `static-server` Consul workload:
```bash
kubectl apply -f server/static-server.yaml 
```

Verify connection from networkservicemesh client to consul server:
```bash
kubectl exec -it alpine-nsc -- apk add curl
kubectl exec -it alpine-nsc -- curl 172.16.1.2:8080
```

You should see "hello world" answer.

## Cleanup


```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl delete mutatingwebhookconfiguration ${WH}

kubectl delete crd spiffeids.spiffeid.spiffe.io
kubectl delete ns spire

kubectl delete -k nse-auto-scale 

kubectl delete -f client.yaml

consul-k8s uninstall -auto-approve=true -wipe-data=true

kubectl delete pods --all

kind delete cluster
```
