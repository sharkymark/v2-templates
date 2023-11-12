---
name: Develop in a Ruby on Rails container in a Kubernetes pod
description: The goal is to enable code-server and JetBrains IDEs, and Ruby, and Ruby on Rails
tags: [cloud, kubernetes]
---

# Container for Ruby on Rails development

### Apps included
1. A web-based terminal
1. code-server IDE
1. JetBrains Rubymine IDE (browser)
1. JetBrains Rubymine IDE (locally installed Gateway)

### Included in the container image
1. Ruby 2.6.6, 2.7.2
1. bundler gem
1. Ruby on Rails 7
1. [Dockerfile](https://github.com/sharkymark/dockerfiles/tree/main/rbenv/rubymine)

### Additional user inputs and bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for CPU, memory, and disk storage
1. Install VS Code Ruby debugger extension from Open-VSX marketplace
1. Start code-server IDE
1. Clone the survey app repo called `rubyonrails`
1. Start an employee survey app as a subdomain on 3002

### Bundler and gems

The template has a `coder_app` for the survey app so needs to bundle the gems during `startup_script` with

```sh
    bundle config set --local path './bundled-gems'
    bundle install
```

The Rails server is also started as a daemon in the `startup_script` with

`rails s -p 3002 -b 0.0.0.0 -d`

### Resources

[jetbrains rubymine releases](https://data.services.jetbrains.com/products/releases?code=RM)

[bundler config docs](https://bundler.io/v1.12/man/bundle-config.1.html)

[bundler install docs](https://bundler.io/v1.12/man/bundle-install.1.html)

[coder terraform provider docs for script](https://registry.terraform.io/providers/coder/coder/latest/docs/resources/script)