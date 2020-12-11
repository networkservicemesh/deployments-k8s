# deployment-k8s


## How to deploy spire?

To deploy the spire run following command
```
    kubectl apply -k spire/

```


## How to deploy nsm?

To deploy the nsm run following command
```bash
kubectl apply -k nsm/
```

## How to register nsm spire entry?

Currently, we are working on automatization and this step will be removed soon. 
For now, to register nsm into spire need to run following command:
```bash
kubectl exec -n spire spire-server-0 -- \
					/opt/spire/bin/spire-server entry create \
					-spiffeID spiffe://example.org/ns/spire/sa/spire-agent \
					-selector k8s_sat:cluster:nsm-cluster \
					-selector k8s_sat:agent_ns:spire \
					-selector k8s_sat:agent_sa:spire-agent \
					-node
kubectl exec -n spire spire-server-0 -- \
						/opt/spire/bin/spire-server entry create \
						-spiffeID spiffe://example.org/ns/nsm-system/sa/default \
						-parentID spiffe://example.org/ns/spire/sa/spire-agent \
						-selector k8s:ns:nsm-system \
						-selector k8s:sa:default
```

