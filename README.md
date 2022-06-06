<p align="center">
  <a href="https://www.networkservicemesh.io/"><img src="https://github.com/cncf/artwork/blob/master/projects/networkservicemesh/horizontal/color/networkservicemesh-horizontal-color.png?raw=true" width="70%" height="70%"></a>
</p>

# deployment-k8s

This repository provides native kubernetes yaml deployments and markdown examples for Network Service Mesh.

## Contents

* [Applications](./apps)
* Examples
    * [Basic examples](./examples/basic) 
    * [Interdomain and floating interdomain examples](./examples/interdomain)
        *[NSM and Istio interdomain example](./examples/nsm_istio/)
        *[NSM and Monolith interdomain example](./examples/k8s_monolith/)
        *[NSM and floating interdomain vl3 example](./examples/interdomain/usecases/FloatingVl3/)
        *[And other usecases](./examples/interdomain/usecases/)
    * [Open telemetry examples](./examples/observability/)
    * [Features examples](./examples/features)
        * [OPA example](./examples/features/opa)
        * [IPv6 examples](./examples/features/ipv6)
        * [Dual stack example](./examples/features/dual-stack)
        * [Jaeger example](./examples/features/jaeger)
        * [DNS Example](./examples/features/dns)
        * [Admisson webhook Example](./examples/features/webhook)
        * [Policy based routing Example](./examples/features/policy-based-routing/)
        * [NSM Webhook Example](./examples/features/webhook)
        * [Mutually aware nses Example](./examples/features/mutually-aware-nses/)
        * [vl3 + Topology aware scale from zero Example](./examples/features/vl3)     
        * [Select forwarder Example](./examples/features/select-forwarder/) 
        * [Exclude prefixes Example](./examples/features/exclude-prefixes/)       
        * [vl3 Example](./examples/features/vl3)
        * [Topology aware scale from zero](./examples/features/scale-from-zero)
        * [And other features](./examples/features)
    * [SRIOV examples](./examples/sriov)
    * [OVS examples](./examples/ovs)
    * [Memory registry backend examples](./examples/memory)
    * [Heal and resilience examples](./examples/heal)

## Requirements
Minimum required ```kubectl``` client version is ```v1.21.0```

## Using local applications

By default `deployments-k8s` uses applications in github ref format. For local development you can use [`to-local.sh`](./to-local.sh)
script:
```
$ ./to-local.sh
```
It translates all github refs to local paths. If you want to switch back to github refs, you can use [`to-ref.sh`](./to-ref.sh)
script:
```
$ ./to-ref.sh
```
For some cases you may probably need to share your local changes with someone else. In such case please use [`to-export.sh`](./to-export.sh)
instead of `to-local.sh`:
```
$ ./to-export.sh
```
IMPORTANT: `to-export.sh` cannot be undone back to github refs format with `to-ref.sh`. Please don't use it for local
development, use it only for sharing your branch with someone else.