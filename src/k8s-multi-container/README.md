---
name: Develop with 4 containers in a Kubernetes pod including PostgresSQL
description: The goal is to enable 4 containers, Postgres, Go, DBeaver amd pgAdmin in a K8s pod 
tags: [cloud, kubernetes]
---

# 4 containers in a Kubernetes pod

### Apps included
1. A web-based terminal
1. code-server (VS Code in a browser)
1. DBeaver web UI
1. pgAdmin web UI

### Images for the 4 containers
1. [Go](https://hub.docker.com/r/codercom/enterprise-golang)
1. [Postgres](https://hub.docker.com/_/postgres)
1. [DBeaver](https://hub.docker.com/r/dbeaver/cloudbeaver)
1. [pgAdmin](https://hub.docker.com/r/dpage/pgadmin4/)

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)

### defaults
1. (pgAdmin) Username: `pgadmin@pgadmin.org` Password: `pgadmin`
1. (Postgres) Username: `postgres` Password: `postgres`
1. (DBeaver) You create the username and password during the first use of DBeaver - I created: `cbadmin`, `cbadmin` for username and password

### psql
The `startup_script` installs `psql` with `pip3` to connect to PostgreSQL from a terminal.

`psql -U postgres -h localhost`

### go8 API steps
1. `cd` into `go8` and `go run cmd/migrate/main.go` this will fail if `go8_db` database is not in PostgreSQL
1. Start the API server `go run cmd/go8/main.go`
1. See all routes `go run cmd/route/main.go`
1. forward to API port to your local machine with the Coder CLI `coder tunnel <workspace name> --tcp 3080`
1. Open another local terminal session to make API calls with `curl`

#### Add book

```sh
curl -v --location --request POST 'http://localhost:3080/api/v1/book' \
 --header 'Content-Type: application/json' \
 --data-raw '{
    "title": "One Hundred Years of Solitude",
    "image_url": "https://en.wikipedia.org/wiki/One_Hundred_Years_of_Solitude",
    "published_date": "1967-07-31T15:04:05.123499999Z",
    "description": 
    "a 1967 novel by Colombian author Gabriel García Márquez that tells the multi-generational story of the Buendía family, whose patriarch, José Arcadio Buendía, founded the fictitious town of Macondo."
  }' \
 | jq
 ```

#### Get all books

```sh
curl --location --request GET 'http://localhost:3080/api/v1/book' | jq
```

### Add author

```sh
curl -X POST 'http://localhost:3080/api/v1/author' --header 'Authorization: Bearer INSERT_JWT' --header 'Content-Type: application/json' --data-raw '{"first_name": "Gabriel García", "last_name": "Márquez"}'
```

### Get author

```sh
curl -X GET 'http://localhost:3080/api/v1/author/1'
```

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to enter a valid workspaces_namespace at workspace creation to point to the Kubernetes namespace the workspace will be deployed to

### Resources
[API example repo](https://github.com/gmhafiz/go8)

[Postgres image](https://hub.docker.com/_/postgres)

[Golang Dockerfile](https://github.com/coder/enterprise-images/tree/main/images/golang)

[Golang image](https://hub.docker.com/r/codercom/enterprise-golang)

[DBeaver](https://hub.docker.com/r/dbeaver/cloudbeaver)

[pgAdmin](https://hub.docker.com/r/dpage/pgadmin4/)