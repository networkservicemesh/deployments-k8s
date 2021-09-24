# Enable Jaeger Tracing for NSM Components

## Prerequisites

NSM supports tracing via the [Jaeger](https://www.jaegertracing.io/docs/1.26/architecture/)
OpenTracing export mechanism.  Each NSM component is a "tracer" (OpenTracing
Span producer) and integrates with the `jaeger-client-go` library to export
traces to Jaeger agents.  Therefore, NSM's tracing support requires access to
a Jaeger installation's agent service.

Jaeger installation is not in the scope of NSM, however, the Jaeger community
has documented an all-in-one installation that is useful as a quick start for
Kubernetes and NSM examples.

[Jaeger All-in-one Installation](https://www.jaegertracing.io/docs/1.26/operator/#quick-start---deploying-the-allinone-image)

The following examples assume the Jaeger operator CRD was created with the
name `simplest` as in the all-in-one document shows:

```bash
kubectl apply -n observability -f - <<EOF
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: simplest
EOF
```

**NOTE:**  Exposing the resulting `simplest-query` Kubernetes service's
`http-query` port (e.g. via port-forwarding) gives access to the Jaeger UI--
e.g. the following forwards `http://localhost:30686` to the Jaeger UI:

```bash
kubectl port-forward svc/simplest-query -n observability 30686:16686
```

## Jaeger Settings for NSM Components

NSM makes use of the [jaeger-client-go](https://github.com/jaegertracing/jaeger-client-go/tree/v2.22.1) library which defines the following env variables for configuring the tracer component:  https://github.com/jaegertracing/jaeger-client-go/blob/master/README.md#environment-variables

For the Jaeger all-in-one installation named `simplest`, the NSM
components' `jaeger-client-go` tracers need to export traces via the
Kubernetes service named `simplest-agent` in the `observability` namespace.
Therefore, each NSM container integrating the `jaeger-client-go` needs the
`JAEGER_AGENT_HOST` environment variable set to `simplest-agent.observability`.

A kustomization can make use of [jaeger-patch.yaml](jaeger-patch.yaml) as a
json6902 patch for the first container in a Kubernetes `Deployment` or
`Daemonset`.  The following `kustomization.yaml` is equivalent to the
[examples/basic](../../basic/README.md) with Jaeger tracing configured.

```bash
cat ../../examples/basic/kustomization.yaml > kustomization.yaml << EOF
patchesJson6902:
- target:
    group: apps
    version: v1
    kind: DaemonSet
    name: forwarder-vpp
  path: jaeger-patch.yaml
- target:
    group: apps
    version: v1
    kind: DaemonSet
    name: nsmgr
  path: jaeger-patch.yaml
- target:
    group: apps
    version: v1
    kind: Deployment
    name: registry-k8s
  path: jaeger-patch.yaml
EOF
```

Results in the following kustomization.yaml:
```bash
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: nsm-system

bases:
- ../../apps/nsmgr
- ../../apps/forwarder-vpp
- ../../apps/registry-k8s
- ../../apps/admission-webhook-k8s

patchesJson6902:
- target:
    group: apps
    version: v1
    kind: DaemonSet
    name: forwarder-vpp
  path: jaeger-patch.yaml
- target:
    group: apps
    version: v1
    kind: DaemonSet
    name: nsmgr
  path: jaeger-patch.yaml
- target:
    group: apps
    version: v1
    kind: Deployment
    name: registry-k8s
  path: jaeger-patch.yaml
```

### Enable Jaeger for NSC and NSE examples

It's possible to enable Jaeger for the example NSCs and NSEs via the same
approach in their `kustomization` setup.

**NOTE:** due to a limitation in the `kustomize` implementation the patch file
must be in the same directory as the kustomization.yaml or a sub-directory.


Create the patch in the kustomization directory:
```bash
cat > jaeger-patch.yaml <<EOF
- op: add
  path: /spec/template/spec/containers/0/env/-
  value:
    name: JAEGER_AGENT_HOST
    value: simplest-agent.observability
EOF
```

Append the NSC and NSE deployment patch target rules to the example
`kustomization` (NOTE: the following is for the "Memif2Kernel" example):

```bash
cat ../../use-cases/Memif2Kernel/kustomization.yaml > kustomization.yaml-Memif2Kernel-jaeger << EOF
patchesJson6902:
- target:
    group: apps
    version: v1
    kind: Deployment
    name: nsc-kernel
  path: jaeger-patch.yaml
- target:
    group: apps
    version: v1
    kind: Deployment
    name: nse-memif
  path: jaeger-patch.yaml
EOF
```
