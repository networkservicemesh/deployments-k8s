# Feature OPA

Let's consider a current simplified version of NSM authorization.

![NSM Authorize Scheme](./scheme.png "NSM Authorize Scheme")

*Note: This scheme simplified many of the complex things that happen in every client and endpoint for simplicity. To understand it in deep consider looking at the source code of applications.*

Each application in the path of NSM request doesn't trust anybody. Each endpoint doesn't trust the client and on each incoming request the endpoint validates tokens in the path and if they invalid then the endpoint returns an error.
Each client also doesn't trust the endpoint and checks tokens on the response.

Authorization checks enabled by default in NSM. 
For example, all [use-cases](../../use-cases) are using valid token chains by default. 

The example below will do token from step1 from the scheme as invalid.
Expected that Endpoint(in this case NSMgr) will fail the Request from the client on step 4.

## Run

Create test namespace:
```bash
kubectl create ns ns-opa
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/opa?ref=4cdc190a5f6abf8cdf9323e443feb4cd346ddb70
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel -n ns-opa
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-opa
```

ind nsc and nse pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-kernel -n ns-opa --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-opa --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Check that NSC is not privileged and it cannot connect to NSE.

```bash
kubectl logs ${NSC} -n ns-opa | grep "PermissionDenied desc = no sufficient privileges"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-opa
```
