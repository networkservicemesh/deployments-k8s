# NSM + Consul + vl3 interdomain example over kind clusters

This example shows how Consul can be used over NSM with vl3. 


## Requires

- [Load balancer](../loadbalancer)
- [Interdomain DNS](../dns)
- [Interdomain spire](../spire)
- [Interdomain nsm](../nsm)


## Run

References:
https://learn.hashicorp.com/tutorials/consul/deployment-guide?in=consul/production-deploy
https://learn.hashicorp.com/tutorials/consul/tls-encryption-secure
https://learn.hashicorp.com/tutorials/consul/service-mesh-with-envoy-proxy?in=consul/developer-mesh
Open terminal with port forwarding from ssh 
```bash
ssh -L 127.0.0.1:9002:127.0.0.1:9002 amalysheva@192.168.2.74

ssh -L 127.0.0.1:8500:127.0.0.1:8500 amalysheva@192.168.2.74
```
kind get kubeconfig --name cluster-1 > /tmp/config1
kind get kubeconfig --name cluster-2 > /tmp/config2

/home/amalysheva/kind get kubeconfig --name cluster-1 > /tmp/config1
/home/amalysheva/kind get kubeconfig --name cluster-2 > /tmp/config2

export KUBECONFIG1=/tmp/config1
export KUBECONFIG2=/tmp/config2
export KUBECONFIG=$KUBECONFIG1
export KUBECONFIG=$KUBECONFIG2

CLUSTER1_CIDR=172.18.121.128/25
CLUSTER2_CIDR=172.18.123.128/25

Nhfrnjh123!

Load custom images with preinstalled consul and envoy onto clusters:
```bash
docker build -t consul-client:latest ./examples/interdomain/nsm_consul_vl3/dockerfile/
kind load docker-image consul-client:latest  --name cluster-1
kind load docker-image consul-client:latest  --name cluster-2
```
