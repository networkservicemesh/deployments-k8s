## Start docker container

This example shows how to start docker container using `docker compose`

## Run

Create kustomization file. Use static IP for the kind cluster. Make sure that user defined `kind` network with 172.18.0.0/16 is used.
For example: `docker network create kind --subnet=172.18.0.0/16`
```bash
cat > docker-compose.override.yaml <<EOF
---
networks:
  kind:
    external: true

services:
  nse-simple-vl3-docker:
    networks:
      kind:
        ipv4_address: 172.18.0.50
    environment:
      NSM_TUNNEL_IP: 172.18.0.50
EOF
```

Download docker-compose base file:
```bash
curl https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/9f6a4448acd27cc6bc6f210f647410025141854d/apps/nse-simple-vl3-docker/docker-compose.yaml -o docker-compose.yaml
```

Run docker-nse:
```bash
docker compose -f docker-compose.yaml -f docker-compose.override.yaml up -d
```

## Cleanup

```bash
docker compose -f docker-compose.yaml -f docker-compose.override.yaml down
```
