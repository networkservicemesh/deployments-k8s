

## Requires

- [Load balancer](../interdomain/loadbalancer)
- [Interdomain DNS](../interdomain/dns)
- [Interdomain spire](../interdomain/spire)
- [Interdomain nsm](../interdomain/nsm)


### Start vl3
```bash
kubectl --kubeconfig=$KUBECONFIG1 create ns ns-vl3
kubectl --kubeconfig=$KUBECONFIG1 apply -k ./vl3-basic
kubectl --kubeconfig=$KUBECONFIG1 -n ns-vl3 wait --for=condition=ready --timeout=2m pod -l app=vl3-ipam
```

### Install kumactl

Install kumactl by following [Kuma docs](https://kuma.io/docs/1.7.x/installation/kubernetes/)

### Create control-plane configuration
```bash
kumactl install control-plane > ./control-plane
```

### Start the control-plane on the first cluster
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k ./control-plane
kubectl --kubeconfig=$KUBECONFIG1 -n default wait --for=condition=ready --timeout=3m pod -l app=kuma-control-plane
```

### Start redis database with the sidecar on the first cluster
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f demo-redis.yaml
kubectl --kubeconfig=$KUBECONFIG1 -n default wait --for=condition=ready --timeout=3m pod -l app=redis
```

### Start counter page with the sidecar on the second cluster
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f demo-app.yaml
kubectl --kubeconfig=$KUBECONFIG2 -n default wait --for=condition=ready --timeout=3m pod -l app=demo-app
```

### Forward ports to open counter page
```bash
kubectl --kubeconfig=$KUBECONFIG2 port-forward svc/demo-app -n kuma-demo 5000:5000
```

Go to [locahost:5000](http://localhost:5000) to get the counter page.
