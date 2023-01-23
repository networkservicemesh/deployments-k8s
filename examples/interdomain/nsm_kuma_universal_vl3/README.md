## Requires

- [Load balancer](../loadbalancer)
- [Interdomain DNS](../dns)
- Interdomain spire
    - [Spire on first cluster](../../spire/cluster1)
    - [Spire on second cluster](../../spire/cluster2)
    - [Spiffe Federation](../spiffe_federation)
- [Interdomain nsm](../nsm)

## Run
1. Start vl3
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/nsm_kuma_universal_vl3/vl3-dns?ref=a1d983c67a1a38d491bb5a5f7290e66a24a87b00
kubectl --kubeconfig=$KUBECONFIG1 -n ns-dns-vl3 wait --for=condition=ready --timeout=5m pod -l app=vl3-ipam
```

2. Install kumactl

Install kumactl by following [Kuma docs](https://kuma.io/docs/1.7.x/installation/kubernetes/)
```bash
curl -L https://kuma.io/installer.sh | VERSION=1.7.0 ARCH=amd64 bash -
export PATH=$PWD/kuma-1.7.0/bin:$PATH
```

3. Create control-plane configuration
```bash
kumactl generate tls-certificate --hostname=control-plane-kuma.my-vl3-network --hostname=kuma-control-plane.kuma-system.svc --type=server --key-file=./tls.key --cert-file=./tls.crt
```
```bash
cp ./tls.crt ./ca.crt
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/a1d983c67a1a38d491bb5a5f7290e66a24a87b00/examples/interdomain/nsm_kuma_universal_vl3/namespace.yaml
kubectl --kubeconfig=$KUBECONFIG1 create secret generic general-tls-certs --namespace=kuma-system --from-file=./tls.key --from-file=./tls.crt --from-file=./ca.crt
```
```bash
kumactl install control-plane --tls-general-secret=general-tls-certs --tls-general-ca-bundle=$(cat ./ca.crt | base64) > control-plane.yaml
```
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- control-plane.yaml

patchesStrategicMerge:
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/a1d983c67a1a38d491bb5a5f7290e66a24a87b00/examples/interdomain/nsm_kuma_universal_vl3/patch-control-plane.yaml
EOF
```

4. Start the control-plane on the first cluster
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k .
```

5. Start redis database with the sidecar on the first cluster
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/a1d983c67a1a38d491bb5a5f7290e66a24a87b00/examples/interdomain/nsm_kuma_universal_vl3/demo-redis.yaml
kubectl --kubeconfig=$KUBECONFIG1 -n kuma-demo wait --for=condition=ready --timeout=5m pod -l app=redis
```

6. Start counter page with the sidecar on the second cluster
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/a1d983c67a1a38d491bb5a5f7290e66a24a87b00/examples/interdomain/nsm_kuma_universal_vl3/demo-app.yaml
kubectl --kubeconfig=$KUBECONFIG2 -n kuma-demo wait --for=condition=ready --timeout=5m pod -l app=demo-app
```

7. Forward ports to open counter page
```bash
kubectl --kubeconfig=$KUBECONFIG2 port-forward svc/demo-app -n kuma-demo 8081:5000 &
```

8. Send the request and check the response for no errors
```bash
response=$(curl -X POST localhost:8081/increment)
echo $response | grep '"err":null'
```

You can also go to [locahost:8081](https://localhost:8081) to get the counter page and test the application yourself.

## Cleanup
```bash
pkill -f "port-forward"
kubectl --kubeconfig=$KUBECONFIG1 delete ns kuma-system kuma-demo ns-dns-vl3
kubectl --kubeconfig=$KUBECONFIG2 delete ns kuma-demo
rm tls.crt tls.key ca.crt kustomization.yaml control-plane.yaml
rm -rf kuma-1.7.0
```
