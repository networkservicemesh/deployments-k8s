# vL3 Load Balancer

This example shows what is a vL3 Load Balancer (LB) and how it works.

## Description

We all know and use Kubernetes Services in our work. 
Service is a method for exposing a network application that is running as one or more Pods in your cluster. It distributes traffic across a set of selected Pods.

To define a Kubernetes Service:
```
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app.kubernetes.io/name: MyApp
  ports:
    - protocol: TCP
      port: 80
      targetPort: 9376
```
Now you can reach the service by its name.

It turned out that we can use a similar mechanism in our vL3 networks - we can use a **vL3 Load Balancer**.
Being on the same vL3 network, clients can behave like pods - they can communicate with each other. Using selectors, we can combine some of them to implement a service.
vL3-LB will help us with this. We will call these clients that implement the service as _"real servers"_.

So, vL3-LB has the following parameters:

| NSM env            | Description                                                        |
|--------------------|--------------------------------------------------------------------|
| `NSM_SELECTOR`     | labels that group the vL3 clients we need to implement any service |
| `NSM_PROTOCOL`     | TCP or UDP IP protocol                                             |
| `NSM_PORT`         | LB port                                                            |
| `NSM_TARGET_PORT`  | real server port                                                   |

vL3-LB is a vL3-network client that monitors the real servers using `NSM_SELECTOR`. It has its own DNS name that we can use.<br />

**Example of monitoring:**

![NSM vL3 Diagram](./diagram1.svg "vL3-LB monitoring")
<br />_Please note: The network configuration is given as an example. It can have a different number of elements._
<br /><br />
In the current example, we want to get a _finance_ service for processing **http requests**. <br />
After calling the command `$:curl finance:8080`, the DNS name is converted to the IP address of the Load Balancer. <br />
When the http request reaches the balancer, it converts the destination address to the address of the real server.

**Example of the data path:**<br />

![NSM vL3 Diagram](./diagram2.svg "vL3-LB data path")
<br />_Please note: The IP addresses are given as an example, they may change from run to run._

## Run

Deploy the vL3 network service, vL3-NSE, vL3-LB, finance-servers and finance-client (the last 3 are actually clients of the vL3 network) (see `kustomization.yaml`):
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/vl3-lb?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Wait for vL3-clients to be ready:
```bash
kubectl wait --for=condition=ready --timeout=2m pod -l type=vl3-client -n ns-vl3-lb
```

Send an http-request from the finance-client:
```bash
kubectl exec deployments/finance-client -n ns-vl3-lb -- curl -s finance.vl3-lb:8080 | grep "Hello! I'm finance-server"
```
In the response you will see the name of the real server that performed the processing.
If you run the command above many times, you will see that load balancing occurs and the responses are returned by different handlers.

## Cleanup

To clean up the example just follow the next command:
```bash
kubectl delete ns ns-vl3-lb
```
