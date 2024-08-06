---
name: Yaml to configure a standalone Coder deployment
description: The goal is to show how a Yaml file can simplify a standalone deployment
tags: [cloud, yaml]
---

# Yaml to standardize a standalone Coder deployment

### Start the Coder control plane

Running Coder with `coder server` is quick and easy. However it can get unwieldy if you are specifying environment variables.

Start Coder with this Yaml file:

```sh
coder server --config coder.yaml
```

### Export your deployment's configuration as STDOUT Yaml

```sh
coder server --write-config=true
```

### Read through the plethora of configuration settings for a Coder deployment

```sh
coder server --help
```

Search for a specific command or topic

```sh
coder server --help | grep DERP
```
