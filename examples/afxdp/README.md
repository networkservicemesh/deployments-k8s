# AF_XDP forwarder-vpp management interface

Contains a setup for NSM that includes `nsmgr`, `forwarder-vpp`, `registry-k8s`, `admission-webhook`.
\
Unlike the [basic setup](../basic), which uses `AF_PACKET` management interface by default, we set `AF_XDP` here.

_**Note:** this is experimental feature. It may not work on some clusters._

The diagram below shows the movement of traffic within the forwarder-vpp:

![NSM kernel2kernel Diagram](./diagram.svg "NSM Kernel2Kernel Scheme")

Packets arriving at the network interface are processed by the eBPF program, which decides how to redirect the traffic.
If the packet belongs to the NSM interface it forwards it to the VPP, otherwise it goes to the Linux network stack.
## Requires

- [spire](../spire/single_cluster)

## Includes

- [Memif to Memif Connection](../use-cases/Memif2Memif)
- [Kernel to Kernel Connection](../use-cases/Kernel2Kernel)
- [Kernel to Memif Connection](../use-cases/Kernel2Memif)
- [Memif to Kernel Connection](../use-cases/Memif2Kernel)
- [Kernel to Ethernet to Kernel Connection](../use-cases/Kernel2Ethernet2Kernel)
- [Memif to Ethernet to Memif Connection](../use-cases/Memif2Ethernet2Memif)
- [Kernel to Ethernet to Memif Connection](../use-cases/Kernel2Ethernet2Memif)
- [Memif to Ethernet to Kernel Connection](../use-cases/Memif2Ethernet2Kernel)
- [Kernel to IP to Kernel Connection](../use-cases/Kernel2IP2Kernel)
- [Memif to IP to Memif Connection](../use-cases/Memif2IP2Memif)
- [Kernel to IP to Memif Connection](../use-cases/Kernel2IP2Memif)
- [Memif to IP to Kernel Connection](../use-cases/Memif2IP2Kernel)
- [Simple OPA example](../features/opa)
- [Kernel2Kernel IPv6 example](../features/ipv6/Kernel2Kernel_ipv6)
- [Memif2Memif IPv6 example](../features/ipv6/Memif2Memif_ipv6)
- [Kernel2IP2Kernel IPv6 example](../features/ipv6/Kernel2IP2Kernel_ipv6)
- [Kernel2IP2Memif IPv6 example](../features/ipv6/Kernel2IP2Memif_ipv6)
- [Memif2IP2Kernel IPv6 example](../features/ipv6/Memif2IP2Kernel_ipv6)
- [Memif2IP2Memif IPv6 example](../features/ipv6/Memif2IP2Memif_ipv6)
- [Kernel2Kernel dual stack example](../features/dual-stack/Kernel2Kernel_dual_stack)
- [Kernel2IP2Kernel dual stack example](../features/dual-stack/Kernel2IP2Kernel_dual_stack)
- [Admission webhook](../features/webhook)
- [DNS](../features/dns)
- [Topology aware scale from zero](../features/scale-from-zero)
- [NSE composition](../features/nse-composition)
- [Exclude prefixes](../features/exclude-prefixes)
- [Exclude prefixes client](../features/exclude-prefixes-client)
- [Policy based routing](../features/policy-based-routing)
- [Mutually aware NSEs](../features/mutually-aware-nses)
- [vL3-basic](../features/vl3-basic)
- [vL3 DNS](../features/vl3-dns)
- [vL3-scale-from-zero](../features/vl3-scale-from-zero)
- [Inject clients in namespace via NSM annotation](../features/annotated-namespace)

## Run

Apply NSM resources for basic tests:

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/afxdp?ref=6c7ca57dba7c4fa2740f3abb02cf48935f7cb437
```

Wait for admission-webhook-k8s:

```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```

## Cleanup

To free resources follow the next commands:

```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl delete mutatingwebhookconfiguration ${WH}
kubectl delete ns nsm-system
```
