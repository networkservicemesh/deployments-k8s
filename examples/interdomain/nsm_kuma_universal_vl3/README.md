## Requires

- [Load balancer](../loadbalancer)
- [Interdomain DNS](../dns)
- [Interdomain spire](../spire)
- [Interdomain nsm](../nsm)

## Run
1. Start vl3
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k ./vl3-dns
kubectl --kubeconfig=$KUBECONFIG1 -n ns-dns-vl3 wait --for=condition=ready --timeout=2m pod -l app=vl3-ipam
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
kubectl --kubeconfig=$KUBECONFIG1 apply -f namespace.yaml
kubectl --kubeconfig=$KUBECONFIG1 create secret generic general-tls-certs --namespace=kuma-system --from-file=./tls.key --from-file=./tls.crt --from-file=./ca.crt
```
```bash
kumactl install control-plane --tls-general-secret=general-tls-certs --tls-general-ca-bundle=$(cat ./ca.crt | base64) > ./control-plane/control-plane.yaml
```

4. Start the control-plane on the first cluster
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k ./control-plane
```

5. Start redis database with the sidecar on the first cluster
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f demo-redis.yaml
kubectl --kubeconfig=$KUBECONFIG1 -n kuma-demo wait --for=condition=ready --timeout=3m pod -l app=redis
```

6. Start counter page with the sidecar on the second cluster
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f demo-app.yaml
kubectl --kubeconfig=$KUBECONFIG2 -n kuma-demo wait --for=condition=ready --timeout=3m pod -l app=demo-app
```


7. Forward ports to open counter page
```bash
kubectl --kubeconfig=$KUBECONFIG2 port-forward svc/demo-app -n kuma-demo 5000:5000 &
curl -X POST localhost:5000/increment
```
You should see this answer `{"counter":"1","zone":"local","err":null}`

You can also go to [locahost:5000](https://localhost:5000) to get the counter page and test the application yourself.

## Cleanup
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete ns kuma-system kuma-demo ns-dns-vl3
kubectl --kubeconfig=$KUBECONFIG2 delete ns kuma-demo
rm tls.crt tls.key ca.crt
rm -rf kuma-1.7.0
```
