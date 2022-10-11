# Breaking up an application monolith with NSM

There are many existing applications in the world which consist of a collection of monolith servers.
If we want break such monoliths up into cloud native apps bit by bit by pulling services out into Pods, we can use these examples.
It shows how to establish communications between services that have been pulled into Pods and those services that remain on the monolith.

This is achieved by running docker containers outside the cluster.

**_The configuration of the following examples only works with [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) kubernetes cluster._**
The reason is the availability of the kubernetes cluster and the docker container for each other. If you are using a different cluster, please configure the routing.

## Includes

- [External NSC](./external_nsc)
- [External NSE](./external_nse)
