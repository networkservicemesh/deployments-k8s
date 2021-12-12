# deployment-k8s

This repository provides kubernetes yaml deployments and markdown examples for NSM.

## Contents

* [Applications](./apps)
* Examples
    * [Basic examples](./examples/basic) 
    * [Interdomain and floating interdomain examples](./examples/interdomain)
    * [Features examples](./examples/features)
        * [OPA example](./examples/features/opa)
        * [IPv6 examples](./examples/features/ipv6)
        * [DNS Example](./examples/features/dns)
        * [Admisson webhook Example](./examples/features/webhook)
        * [Topology aware scale from zero](./examples/features/scale-from-zero)
    * [SRIOV examples](./examples/sriov)
    * [OVS examples](./examples/ovs)
    * [Memory examples](./examples/memory)
    * [Heal examples](./examples/heal)

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