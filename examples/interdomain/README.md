# Basic examples

This setup is basic for interdomain examples on two clusters. This setup can be used to check next examples: 
- [Consul](./nsm_consul)
- [Istio booking example](./nsm_istio_booking)

## Requires

- [Load balancer](./loadbalancer)
- [Interdomain DNS](./dns)
- Interdomain spire
    - [Spire on first cluster](../spire/cluster1)
    - [Spire on second cluster](../spire/cluster2)
    - [Spiffe Federation](./spiffe-federation)
- [Interdomain nsm](./nsm)


## Includes

- [NSM + Consul](./nsm_consul)
- [NSM vl3 + Consul](./nsm_consul_vl3)
- [NSM + Istio](./nsm_istio)
- [NSM vl3 + Kuma universal](nsm_kuma_universal_vl3)


