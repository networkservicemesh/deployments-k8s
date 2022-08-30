## Requires

- [Load balancer](../interdomain/loadbalancer)
- [Interdomain DNS](../interdomain/dns)
- [Interdomain spire](../interdomain/spire)
- [Interdomain nsm](../interdomain/nsm)


### Start vl3
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k ./vl3-dns
kubectl --kubeconfig=$KUBECONFIG1 -n ns-vl3 wait --for=condition=ready --timeout=2m pod -l app=vl3-ipam
```

### Install kumactl

Install kumactl by following [Kuma docs](https://kuma.io/docs/1.7.x/installation/kubernetes/)

### Create control-plane configuration
```bash
kumactl generate tls-certificate --hostname=control-plane-kuma.my-vl3-network --hostname=kuma-control-plane.kuma-system.svc --type=server --key-file=./tls.key --cert-file=./tls.crt
cp ./tls.crt ./ca.crt
kubectl --kubeconfig=$KUBECONFIG1 apply -f namespace.yaml
kubectl --kubeconfig=$KUBECONFIG1 create secret generic general-tls-certs --namespace=kuma-system --from-file=./tls.key --from-file=./tls.crt --from-file=./ca.crt

kumactl install control-plane --tls-general-secret=general-tls-certs --tls-general-ca-bundle=$(cat ./ca.crt | base64) > ./control-plane/control-plane.yaml
kumactl install control-plane > ./control-plane/control-plane.yaml
```

### Start the control-plane on the first cluster
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k ./control-plane
```

### Start redis database with the sidecar on the first cluster
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f demo-redis.yaml
kubectl --kubeconfig=$KUBECONFIG1 -n kuma-demo wait --for=condition=ready --timeout=3m pod -l app=redis
```

### Start counter page with the sidecar on the second cluster
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f demo-app.yaml
kubectl --kubeconfig=$KUBECONFIG2 -n kuma-demo wait --for=condition=ready --timeout=3m pod -l app=demo-app
```

### Forward ports to open counter page
```bash
kubectl --kubeconfig=$KUBECONFIG2 port-forward svc/demo-app -n kuma-demo 5000:5000
```

Go to [locahost:5000](https://localhost:5000) to get the counter page and test the application.
