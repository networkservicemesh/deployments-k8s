## Start docker container

This example shows how to start docker container using `docker compose`

## Run

Create kustomization file for the kind cluster:
```bash
cat > docker-compose.override.yaml <<EOF
---
networks:
  kind:
    external: true

services:
  nsc-simple-docker:
    networks:
      - kind
    environment:
      NSM_NETWORK_SERVICES: kernel://kernel2ip2kernel-monolith-nsc@k8s.nsm/nsm-1
EOF
```

Download docker-compose base file:
```bash
curl https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/d76f407ceb8a13c664272b116ead7f2d2b201eef/apps/nsc-simple-docker/docker-compose.yaml -o docker-compose.yaml
```

Run docker-nsc:
```bash
docker compose -f docker-compose.yaml -f docker-compose.override.yaml up -d
```

## Cleanup

```bash
docker compose -f docker-compose.yaml -f docker-compose.override.yaml down
```
```bash
rm docker-compose.yaml
```
