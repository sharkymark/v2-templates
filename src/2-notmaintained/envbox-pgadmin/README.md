---
name: Run PostgreSQL and pgAdmin withd docker-compose in a Kubernetes pod
description: Using Docker to run PostgreSQL and pgAdmin
tags: [cloud, kubernetes]
---

# Kubernetes pod with a privileged container running dockerd

### Apps included
1. A web-based terminal
1. code-server
1. pgAdmin RDBMS web admin tool

### Template Admin inputs
1. namespace
1. K8s permissions method (.kube/config or control plane service account)
1. Envbox inputs (e.g., inner and outer container CPU, Memory, mounts)

### Additional bash scripting
1. Clone the PostgreSQL and pgAdmin docker-compose repo
1. Start PostgreSQL and pgAdmin on port `5050` to show in web-based port forwarding

### Default credentials (username/password)
1. PostgreSQL: `postgres/postgres`
1. pgAdmin: `pgadmin@pgadmin.org/pgadmi`

### pgAdmin Add Server
1. Host name: `postgres`
2. Port: `5432`
3. Username: `postgres`
4. Password: `postgres`
### Resources

[envbox docs](https://coder.com/docs/v2/latest/templates/docker-in-workspaces#envbox)

[envbox OSS project](https://github.com/coder/envbox)

[Nestybox (acquired by Docker, Inc.) - creators of sysbox container runtime](https://github.com/nestybox/sysbox/blob/master/docs/user-guide/security.md)

[docker-compose repo](https://github.com/sharkymark/pgadmin/tree/main)

[docker cli run commands](https://docs.docker.com/engine/reference/commandline/run/)