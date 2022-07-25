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
  nse-simple-vl3-docker:
    networks:
      - kind
EOF
```

Download docker compose base file:
```bash
curl https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/78a9551364dc6de9b0cf4b8c2b6f796d899c6c0a/apps/nse-simple-vl3-docker/docker-compose.yaml -o docker-compose.yaml
```

Run docker-nse:
```bash
docker compose -f docker-compose.yaml -f docker-compose.override.yaml up -d
```

## Cleanup

```bash
docker compose -f docker-compose.yaml -f docker-compose.override.yaml down
```
